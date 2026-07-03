import os
import json
import re

BASE_DIR = "/Users/kingofhell/Projects/indiverse-engineering-platform"

def run_validation():
    errors = []
    
    # 1. Verify required directories
    required_dirs = [
        "docs/architecture", "docs/adr", "docs/roadmap", "docs/adoption",
        "templates", "rules", "prompts/architecture", "agents", "governance", "mcp", "scripts"
    ]
    for d in required_dirs:
        dir_path = os.path.join(BASE_DIR, d)
        if not os.path.exists(dir_path) or not os.path.isdir(dir_path):
            errors.append(f"Missing required directory: {d}")

    # 2. Verify single source version file
    version_file = os.path.join(BASE_DIR, "VERSION")
    version = "0.0.0"
    if not os.path.exists(version_file):
        errors.append("Missing VERSION file in repository root")
    else:
        with open(version_file, "r") as f:
            version = f.read().strip()

    # 3. Check prompts metadata headers
    prompts_dir = os.path.join(BASE_DIR, "prompts")
    prompt_files_count = 0
    if os.path.exists(prompts_dir):
        required_headers = [
            "Name", "Purpose", "Inputs", "Outputs", "Constraints", "Example", "Expected Result"
        ]
        for root, _, files in os.walk(prompts_dir):
            for file in files:
                if file.endswith(".md"):
                    prompt_files_count += 1
                    filepath = os.path.join(root, file)
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                    for h in required_headers:
                        if f"- **{h}**:" not in content and f"**{h}**:" not in content:
                            errors.append(f"Prompt {file} is missing required metadata header: {h}")

    # 4. Check agents metadata headers
    agents_dir = os.path.join(BASE_DIR, "agents")
    agents_files_count = 0
    if os.path.exists(agents_dir):
        required_headers = [
            "Mission", "Responsibilities", "Allowed Files", "Forbidden Files", "Review Checklist", "Escalation Rules"
        ]
        for file in os.listdir(agents_dir):
            if file.endswith(".md"):
                agents_files_count += 1
                filepath = os.path.join(agents_dir, file)
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                for h in required_headers:
                    if f"- **{h}**:" not in content and f"**{h}**:" not in content:
                        errors.append(f"Agent {file} is missing required metadata header: {h}")

    # 5. Check markdown relative links
    # Look for broken links of format: [Link Text](file:///...) or [Link Text](../...)
    link_pattern = re.compile(r'\[([^\]]+)\]\(([^\)]+)\)')
    for root, _, files in os.walk(BASE_DIR):
        if "node_modules" in root or ".git" in root or ".gemini" in root:
            continue
        for file in files:
            if file.endswith(".md"):
                filepath = os.path.join(root, file)
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                for match in link_pattern.finditer(content):
                    link_text = match.group(1)
                    link_target = match.group(2)
                    # We check relative links targeting other repository files
                    if link_target.startswith(".") or "/" in link_target:
                        if link_target.startswith("file:///"):
                            # Absolute workspace links
                            target_path = link_target.replace("file://", "")
                        elif link_target.startswith("http"):
                            # Ignore external web links in this check
                            continue
                        else:
                            # Relative file links
                            target_path = os.path.abspath(os.path.join(root, link_target))
                        
                        # Strip anchor
                        target_path = target_path.split("#")[0]
                        if not os.path.exists(target_path):
                            errors.append(f"Broken link in {file}: {link_text} targets missing path: {target_path}")

    # Compile report
    report = {
        "platform_version": version,
        "validation_success": len(errors) == 0,
        "statistics": {
            "total_prompts": prompt_files_count,
            "total_agents": agents_files_count,
            "total_templates": len(os.listdir(os.path.join(BASE_DIR, "templates"))) if os.path.exists(os.path.join(BASE_DIR, "templates")) else 0,
            "total_docs": sum(len(files) for _, _, files in os.walk(os.path.join(BASE_DIR, "docs")))
        },
        "errors": errors
    }

    report_path = os.path.join(BASE_DIR, "reports/platform_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    if errors:
        print("Platform Validation FAILED:")
        for err in errors:
            print(f"- {err}")
        return False
    else:
        print("Platform Validation PASSED successfully!")
        print(f"Generated report at: {report_path}")
        return True

if __name__ == "__main__":
    run_validation()

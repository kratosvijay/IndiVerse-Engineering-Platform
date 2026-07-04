class WorkbenchPreferences {
  final String theme;
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final int tabSize;
  final bool wordWrap;
  final bool showMinimap;
  final bool showStickyScroll;
  final bool autoSave;
  final bool autoRestoreSession;
  final double sidebarWidth;
  final double inspectorWidth;
  final double bottomPanelHeight;

  const WorkbenchPreferences({
    this.theme = "Dark Mode",
    this.fontSize = 13.0,
    this.fontFamily = "monospace",
    this.lineHeight = 1.4,
    this.tabSize = 2,
    this.wordWrap = false,
    this.showMinimap = true,
    this.showStickyScroll = true,
    this.autoSave = false,
    this.autoRestoreSession = true,
    this.sidebarWidth = 250.0,
    this.inspectorWidth = 300.0,
    this.bottomPanelHeight = 200.0,
  });

  Map<String, dynamic> toJson() => {
    "theme": theme,
    "fontSize": fontSize,
    "fontFamily": fontFamily,
    "lineHeight": lineHeight,
    "tabSize": tabSize,
    "wordWrap": wordWrap,
    "showMinimap": showMinimap,
    "showStickyScroll": showStickyScroll,
    "autoSave": autoSave,
    "autoRestoreSession": autoRestoreSession,
    "sidebarWidth": sidebarWidth,
    "inspectorWidth": inspectorWidth,
    "bottomPanelHeight": bottomPanelHeight,
  };

  factory WorkbenchPreferences.fromJson(Map<String, dynamic> json) =>
      WorkbenchPreferences(
        theme: json["theme"] ?? "Dark Mode",
        fontSize: (json["fontSize"] as num?)?.toDouble() ?? 13.0,
        fontFamily: json["fontFamily"] ?? "monospace",
        lineHeight: (json["lineHeight"] as num?)?.toDouble() ?? 1.4,
        tabSize: json["tabSize"] ?? 2,
        wordWrap: json["wordWrap"] ?? false,
        showMinimap: json["showMinimap"] ?? true,
        showStickyScroll: json["showStickyScroll"] ?? true,
        autoSave: json["autoSave"] ?? false,
        autoRestoreSession: json["autoRestoreSession"] ?? true,
        sidebarWidth: (json["sidebarWidth"] as num?)?.toDouble() ?? 250.0,
        inspectorWidth: (json["inspectorWidth"] as num?)?.toDouble() ?? 300.0,
        bottomPanelHeight:
            (json["bottomPanelHeight"] as num?)?.toDouble() ?? 200.0,
      );
}

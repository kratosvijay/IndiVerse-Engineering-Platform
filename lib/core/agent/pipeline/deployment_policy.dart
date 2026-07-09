import 'pipeline_models.dart';

abstract interface class DeploymentPolicy {
  String get name;
  bool evaluate(DeploymentTarget target, {bool userApproved = false});
}

class ProductionApprovalPolicy implements DeploymentPolicy {
  const ProductionApprovalPolicy();

  @override
  String get name => 'ProductionApprovalPolicy';

  @override
  bool evaluate(DeploymentTarget target, {bool userApproved = false}) {
    if (target == DeploymentTarget.production) {
      return userApproved; // blocks deployment unless explicitly user-approved
    }
    return true; // auto-approved for dev, qa, staging, local
  }
}

class RolloutPolicy implements DeploymentPolicy {
  const RolloutPolicy();

  @override
  String get name => 'RolloutPolicy';

  @override
  bool evaluate(DeploymentTarget target, {bool userApproved = false}) {
    return true;
  }
}

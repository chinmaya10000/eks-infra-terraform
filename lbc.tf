data "aws_iam_policy_document" "aws_lbc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "aws_lbc" {
  name               = "aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_assume_role.json
}

resource "aws_iam_policy" "aws_lbc" {
  name   = "AWSLoadBalancerController"
  policy = file("${path.module}/iam/AWSLoadBalancerController.json")
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  role       = aws_iam_role.aws_lbc.name
  policy_arn = aws_iam_policy.aws_lbc.arn
}

resource "kubernetes_service_account" "aws_lbc" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lbc.arn
    }
  }
}

resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.4"

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
      }, {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.aws_lbc.metadata[0].name
      }, {
      name  = "replicaCount"
      value = 1
      }, {
      name  = "resources.requests.cpu"
      value = "100m"
      }, {
      name  = "resources.requests.memory"
      value = "128Mi"
      }, {
      name  = "resources.limits.cpu"
      value = "100m"
      }, {
      name  = "resources.limits.memory"
      value = "128Mi"
      }, {
      name  = "vpcId"
      value = module.vpc.vpc_id
  }]

  depends_on = [
    module.eks,
    kubernetes_service_account.aws_lbc
  ]
}






# kubectl get pods -n kube-system
# https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller


# kubectl get ingressclass
# kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
# kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
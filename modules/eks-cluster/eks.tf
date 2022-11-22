resource "aws_iam_role" "eks-cluster" {
  name = "${var.Environment}-eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
# depends_on = [
#     aws_eks_cluster.ogtl-eks-cluster
#   ]
}

resource "aws_iam_role_policy_attachment" "demo-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_eks_cluster" "dbs-eks-cluster" {
  name     = "${var.Environment}-${var.name}"
  role_arn = aws_iam_role.eks-cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.priv-subnet-1.id,
      aws_subnet.priv-subnet-2.id,
      aws_subnet.pub-subnet-1.id,
      aws_subnet.pub-subnet-2.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-AmazonEKSClusterPolicy
  ]

}
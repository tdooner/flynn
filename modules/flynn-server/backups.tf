resource "aws_iam_user" "flynn-backups" {
  name = "flynn-backups"
  path = "/"
}

resource "aws_iam_policy_attachment" "flynn-backups" {
  name = "flynn-backups"
  users = ["${aws_iam_user.flynn-backups.name}"]
  policy_arn = "${aws_iam_policy.flynn-backups.arn}"
}

resource "aws_iam_access_key" "flynn-backups" {
  user = "${aws_iam_user.flynn-backups.name}"
}

resource "aws_s3_bucket" "flynn-backups" {
  bucket = "flynn-backups-tdooner"
  acl = "private"
}

resource "aws_iam_policy" "flynn-backups" {
  name = "flynn-backups"
  path = "/"
  description = "User to upload flynn backups"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1480272378109",
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.flynn-backups.bucket}/*"
    }
  ]
}
EOF
}

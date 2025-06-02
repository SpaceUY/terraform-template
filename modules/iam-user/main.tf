resource "aws_iam_user" "this" {
  count = var.create ? 1 : 0
  name = "${var.prefix}--user"
}

resource "aws_iam_access_key" "this" {
  count = var.create ? 1 : 0
  user = aws_iam_user.this[0].name
}



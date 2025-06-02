output "user_id" {
  value = aws_iam_user.this[0].id
}

output "user_name" {
  value = aws_iam_user.this[0].name
}

output "access_key_id" {
  value = aws_iam_access_key.this[0].id
  sensitive = true
}
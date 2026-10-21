output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.app.public_dns
}

output "frontend_url" {
  description = "Open this in a browser (allow 2-4 minutes after apply for user-data to finish)"
  value       = "http://${aws_instance.app.public_ip}"
}

output "verification_urls" {
  description = "URLs that prove the frontend and each backend container are up"
  value = {
    frontend_health = "http://${aws_instance.app.public_ip}/healthz"
    user_service    = "http://${aws_instance.app.public_ip}/svc/user/"
    product_service = "http://${aws_instance.app.public_ip}/svc/product/"
    cart_service    = "http://${aws_instance.app.public_ip}/svc/cart/"
    order_service   = "http://${aws_instance.app.public_ip}/svc/order/"
  }
}

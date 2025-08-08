

# Uncomment this if you want to create a new hosted zone (if you don't have one already)
# resource "aws_route53_zone" "main" {
#   name = var.domain_name
# }

resource "aws_route53_record" "app_record" {
  zone_id = var.hosted_zone_id
  name    = "app.${var.domain_name}"   # e.g. app.example.com
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

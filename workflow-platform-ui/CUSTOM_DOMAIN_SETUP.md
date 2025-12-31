# Custom Domain Setup Guide

This guide will help you configure your personal domain to point to the AI Agent Workflow Platform POC.

## Prerequisites

- Domain name (e.g., `workflow.yourdomain.com`)
- Access to domain DNS settings
- AWS account with the deployed application

## Option 1: Using AWS Amplify (Easiest)

### Step 1: Deploy to Amplify
1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify)
2. Click "Host web app" → "Deploy without Git"
3. Drag and drop the `build` folder
4. Wait for deployment (2-3 minutes)

### Step 2: Add Custom Domain
1. In Amplify app, click "Domain management"
2. Click "Add domain"
3. Enter your domain (e.g., `yourdomain.com`)
4. Amplify will automatically:
   - Request SSL certificate
   - Provide DNS records to add
5. Add the provided DNS records to your domain registrar
6. Wait for DNS propagation (5-30 minutes)

### Step 3: Access Your App
- Your app will be available at `https://yourdomain.com`
- SSL certificate is automatically managed by Amplify

## Option 2: Using CloudFront + Route 53

### Step 1: Request SSL Certificate
```bash
# Request certificate in us-east-1 (required for CloudFront)
aws acm request-certificate \
  --domain-name workflow.yourdomain.com \
  --validation-method DNS \
  --region us-east-1
```

### Step 2: Validate Certificate
1. Go to [ACM Console](https://console.aws.amazon.com/acm)
2. Click on your certificate
3. Add the provided CNAME record to your DNS
4. Wait for validation (5-30 minutes)

### Step 3: Create CloudFront Distribution
1. Go to [CloudFront Console](https://console.aws.amazon.com/cloudfront)
2. Create distribution with these settings:
   - **Origin Domain:** `workflow-platform-poc-demo.s3.us-east-1.amazonaws.com`
   - **Origin Access:** Create new OAI (Origin Access Identity)
   - **Viewer Protocol Policy:** Redirect HTTP to HTTPS
   - **Alternate Domain Names (CNAMEs):** `workflow.yourdomain.com`
   - **SSL Certificate:** Select your ACM certificate
   - **Default Root Object:** `index.html`
   - **Error Pages:** Add custom error response
     * HTTP Error Code: 404
     * Response Page Path: `/index.html`
     * HTTP Response Code: 200

3. Click "Create Distribution"
4. Wait for deployment (15-20 minutes)

### Step 4: Update DNS
Get your CloudFront domain name:
```bash
aws cloudfront list-distributions \
  --query 'DistributionList.Items[0].DomainName' \
  --output text
```

Add CNAME record to your DNS:
- **Type:** CNAME
- **Name:** workflow (or your subdomain)
- **Value:** `d1234567890.cloudfront.net` (your CloudFront domain)
- **TTL:** 300

### Step 5: Test
Wait for DNS propagation (5-30 minutes), then access:
`https://workflow.yourdomain.com`

## Option 3: Using CloudFront + Route 53 (AWS-Managed DNS)

If your domain is managed by Route 53:

### Step 1: Follow Steps 1-3 from Option 2

### Step 2: Create Route 53 Record
```bash
# Get your hosted zone ID
aws route53 list-hosted-zones

# Get your CloudFront distribution domain
CLOUDFRONT_DOMAIN=$(aws cloudfront list-distributions \
  --query 'DistributionList.Items[0].DomainName' \
  --output text)

# Create A record (Alias)
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "workflow.yourdomain.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "'$CLOUDFRONT_DOMAIN'",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'
```

## DNS Configuration Examples

### For Popular DNS Providers

#### Cloudflare
1. Go to DNS settings
2. Add CNAME record:
   - Type: CNAME
   - Name: workflow
   - Target: your-cloudfront-domain.cloudfront.net
   - Proxy status: DNS only (gray cloud)

#### GoDaddy
1. Go to DNS Management
2. Add record:
   - Type: CNAME
   - Host: workflow
   - Points to: your-cloudfront-domain.cloudfront.net
   - TTL: 1 Hour

#### Namecheap
1. Go to Advanced DNS
2. Add New Record:
   - Type: CNAME Record
   - Host: workflow
   - Value: your-cloudfront-domain.cloudfront.net
   - TTL: Automatic

## Verification

### Check DNS Propagation
```bash
# Check if DNS is propagated
dig workflow.yourdomain.com

# Or use online tool
# https://www.whatsmydns.net/
```

### Test SSL Certificate
```bash
# Check SSL certificate
curl -I https://workflow.yourdomain.com
```

### Access Application
Open browser and navigate to:
`https://workflow.yourdomain.com`

## Troubleshooting

### DNS Not Resolving
- Wait longer (DNS can take up to 48 hours, usually 5-30 minutes)
- Check DNS records are correct
- Clear browser cache

### SSL Certificate Error
- Ensure certificate is validated in ACM
- Check certificate includes your domain name
- Verify CloudFront is using the correct certificate

### 403 Forbidden Error
- Check CloudFront OAI has access to S3 bucket
- Verify bucket policy is correct
- Check CloudFront distribution is deployed

### 404 Errors on Refresh
- Ensure CloudFront error page is configured
- 404 should redirect to `/index.html` with 200 status

## Cost Estimate

- **Amplify:** ~$0.15/GB served + $0.01/build minute
- **CloudFront:** ~$0.085/GB for first 10TB
- **Route 53:** $0.50/hosted zone/month
- **ACM Certificate:** Free

For POC/demo usage: **~$1-5/month**

## Next Steps

After domain is configured:
1. Test all features on custom domain
2. Share URL with stakeholders
3. Monitor usage in AWS Console
4. Consider setting up:
   - CloudWatch monitoring
   - AWS WAF for security
   - CloudFront caching optimization

## Support

For issues:
1. Check AWS CloudWatch logs
2. Verify DNS with `dig` or `nslookup`
3. Check CloudFront distribution status
4. Review ACM certificate validation


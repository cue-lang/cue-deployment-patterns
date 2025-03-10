package platform

#Deployment: {
    preview: hostname: =~ "example-dev.com$"
    preprod: hostname: =~ "example-preprod.com$"
    prod: hostname: =~ "example.com$"
}

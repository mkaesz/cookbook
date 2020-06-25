{
        "version": "9",
        "hosts": {
                "minio": {
                        "url": "https://${minio_server}",
                        "accessKey": "minioadmin",
                        "secretKey": "minioadmin",
                        "api": "s3v4",
                        "lookup": "auto"
                }
        }
}

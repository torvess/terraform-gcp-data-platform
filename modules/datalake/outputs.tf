output "bucket_names" {
    description = "Nomes dos buckets criados por camadas"
    value = {
        for layer, bucket in google_storage_bucket.layers : layer => bucket.name
    }
}

output "bucket_urls" {
    description = "URLs gs:// dos buckets criados por camadas"
    value = {
        for layer, bucket in google_storage_bucket.layers : layer => "gs://${bucket.name}"
    }
}
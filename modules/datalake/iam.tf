resource "google_storage_bucket_iam_member" "data_engineer" {
    for_each = {
        for pair in setproduct(toset(local.layers), toset(var.data_engineer_members)) :
        "${pair[0]}-${pair[1]}" => pair
    }

    bucket = google_storage_bucket.layers[each.value[0]].name
    role   = "roles/storage.objectUser"
    member = each.value[1]
}
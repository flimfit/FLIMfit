from google.cloud import storage
import subprocess
import sys

def upload(bucket, source_file, destination):
    print(f"Uploading {source_file} to {destination}.")
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket)
    blob = bucket.blob(destination)
    blob.upload_from_filename(source_file)
    print(f"Upload complete.")

# Get version string
result = subprocess.run(['git', 'describe', '--abbrev=8'], stdout=subprocess.PIPE)
version = result.stdout.decode('utf-8').strip()

bucket = "flimfit-downloads"
source_file = sys.argv[1]
destination = sys.argv[2]

# Format arguments
source_file = source_file.format(version=version)
destination = destination.format(version=version)

# Upload file
upload(bucket, source_file, destination)

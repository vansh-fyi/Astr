#!/usr/bin/env python3
"""
Upload zones.db to Cloudflare R2 using S3-compatible API.

Prerequisites:
1. Install boto3: pip install boto3
2. Get R2 credentials from Cloudflare Dashboard:
   - Go to R2 > Manage R2 API Tokens
   - Create a token with Object Read & Write permissions
3. Set environment variables:
   - R2_ACCOUNT_ID: Your Cloudflare account ID
   - R2_ACCESS_KEY_ID: R2 API token access key
   - R2_SECRET_ACCESS_KEY: R2 API token secret
   - R2_BUCKET: Bucket name (default: astr-zones)

Usage:
    python upload_to_r2.py
"""

import os
import sys
import hashlib
from pathlib import Path

try:
    import boto3
    from botocore.config import Config
except ImportError:
    print("Please install boto3: pip install boto3")
    sys.exit(1)


def get_file_sha256(filepath: Path) -> str:
    """Calculate SHA-256 hash of a file."""
    sha256 = hashlib.sha256()
    with open(filepath, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    return sha256.hexdigest()


def upload_to_r2():
    # Configuration from environment
    account_id = os.environ.get('R2_ACCOUNT_ID')
    access_key = os.environ.get('R2_ACCESS_KEY_ID')
    secret_key = os.environ.get('R2_SECRET_ACCESS_KEY')
    bucket_name = os.environ.get('R2_BUCKET', 'astr-zones')

    if not all([account_id, access_key, secret_key]):
        print("Missing required environment variables:")
        print("  R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY")
        sys.exit(1)

    # Path to zones.db
    script_dir = Path(__file__).parent
    zones_db = script_dir.parent / 'assets' / 'db' / 'zones.db'

    if not zones_db.exists():
        print(f"zones.db not found at: {zones_db}")
        sys.exit(1)

    file_size = zones_db.stat().st_size
    print(f"zones.db size: {file_size / (1024**3):.2f} GB")

    # Calculate checksum
    print("Calculating SHA-256 checksum...")
    sha256 = get_file_sha256(zones_db)
    print(f"SHA-256: {sha256}")

    # Create S3 client for R2
    endpoint_url = f"https://{account_id}.r2.cloudflarestorage.com"
    
    s3 = boto3.client(
        's3',
        endpoint_url=endpoint_url,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        config=Config(
            signature_version='s3v4',
            s3={'addressing_style': 'path'},
        ),
    )

    # Check if bucket exists, create if not
    try:
        s3.head_bucket(Bucket=bucket_name)
        print(f"Bucket '{bucket_name}' exists")
    except:
        print(f"Creating bucket '{bucket_name}'...")
        s3.create_bucket(Bucket=bucket_name)

    # Upload with multipart for large files
    print(f"\nUploading zones.db to R2 bucket '{bucket_name}'...")
    print("This may take a while for a 5GB file...")

    from boto3.s3.transfer import TransferConfig

    # Use 100MB chunks for multipart upload
    config = TransferConfig(
        multipart_threshold=100 * 1024 * 1024,  # 100MB
        max_concurrency=10,
        multipart_chunksize=100 * 1024 * 1024,  # 100MB chunks
    )

    # Progress callback
    uploaded_bytes = [0]
    
    def progress_callback(bytes_transferred):
        uploaded_bytes[0] += bytes_transferred
        pct = (uploaded_bytes[0] / file_size) * 100
        print(f"\rProgress: {pct:.1f}% ({uploaded_bytes[0] / (1024**3):.2f} GB)", end='', flush=True)

    s3.upload_file(
        str(zones_db),
        bucket_name,
        'zones.db',
        Config=config,
        Callback=progress_callback,
        ExtraArgs={
            'ContentType': 'application/octet-stream',
            'Metadata': {
                'sha256': sha256,
            },
        },
    )

    print(f"\n\n✓ Upload complete!")
    print(f"  Bucket: {bucket_name}")
    print(f"  Object: zones.db")
    print(f"  SHA-256: {sha256}")
    print(f"\nNext steps:")
    print(f"  1. Deploy the Cloudflare Worker: cd cloudflare && wrangler deploy")
    print(f"  2. Update the API URL in the app:")
    print(f"     lib/features/data_layer/providers/cached_zone_repository_provider.dart")


if __name__ == '__main__':
    upload_to_r2()

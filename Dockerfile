# syntax=docker/dockerfile:1.3-labs
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3-pip python3-pil zbar-tools golang ca-certificates openssl
RUN pip3 install pyotp==2.8.0 pyzbar==0.1.9
RUN go install github.com/dim13/otpauth@v0.5.0


RUN cat <<EOF > /decode_qr.py

import urllib, pyzbar.pyzbar, subprocess
from PIL import Image
img = Image.open('/image.png')
for d in pyzbar.pyzbar.decode(img):
    url = d.data.decode('utf-8')
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme == 'otpauth-migration':
        url = subprocess.check_output(['/root/go/bin/otpauth', '-link', url]).decode('utf-8')
        parsed = urllib.parse.urlparse(url)
    secret = urllib.parse.parse_qs(parsed.query)['secret'][0]
    secret = ''.join(c for c in secret if c.isalnum())
    print(secret)

EOF


RUN cat <<EOF > /print_otp.py

import pyotp, os
totp = pyotp.TOTP(os.environ['SEEKREET'].strip())
print(totp.now())

EOF

# easy_totp
**Run one command and have OTP copied to your clipboard**

*Assuming you use Mac and have Docker installed*

I've created this app because I've been annoyed by some service providers that require one-time-passwords
(time-based generated ones, like the ones you copy from Google Authenticator, 1Password, authy, pingid etc.)
while not being security-critical from my point of view.

Beside being able to generate TOTPs, it will also help you to extract TOTP secrets from QR codes for initial setup.
Both original QR-code images and Google Authenticator's backup images are supported.

This repository aims to be:
- as simple as possible, so that you can easily inspect the code and make sure it's not doing anything malicious
  * all code is in a single `Dockerfile`, and it's only couple dozens lines of code
- as portable as possible, so that you can run it on any machine with Docker installed
- as secure as possible, so I try to do everything in the most secure way I can think of:
  * use keychain to store secrets
  * pin versions of pip and golang packages (OS-level packages are not pinned)
  * do not pass secrets as arguments so that they don't appear in the process list
  * recommend secure ways of handling QR code images

## Usage - copy TOTP to clipboard
```shell
$ otp_print my-secret-name | pbcopy
```

## Usage - setup new TOTP from QR code
Make screenshot of QR code in your OTP app and securely send it to your computer (e.g. via Airdrop).
Make sure image is not synced to iCloud or any other cloud storage.
Then run:
```shell
$ otp_qr_setup /path/to/image.png my-secret-name
```
Also, don't forget to:
1. (securely) delete the image after you're done
2. (securely) delete the screenshot from your phone (check "Recently Deleted" folder)


## Installation 
1. Clone and open this repo:
```shell
$ git clone https://github.com/dir01/easy_totp.git && cd easy_totp
```
2. Inspect the Dockerfile to make sure it's not doing anything malicious
```shell
$ cat Dockerfile
```
3. Build the docker image:
```shell
$ docker build . -t easy_totp
```
4. Add these 2 functions to your .bashrc/.zshrc:
```bash
otp_qr_setup() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: otp_qr_setup /path/to/image.png my-secret-name"
    return 1
  fi
  SEEKREET="$(docker run -it -v "$(realpath $1):/image.png" easy_totp python3 /decode_qr.py)"
  security delete-generic-password -a $LOGNAME -s $2
  security add-generic-password -a $LOGNAME -s $2 -w $SEEKREET
  CURRENT_CODE=$(otp_print $2)
  echo
  echo "Success. Current code is $CURRENT_CODE"
  echo "Request new codes with 'otp_print $2'"
}

otp_print() {
  SEEKREET="$(security find-generic-password -w -a $LOGNAME -s "$1")" docker run -it --env SEEKREET easy_totp python3 /print_otp.py
}
```
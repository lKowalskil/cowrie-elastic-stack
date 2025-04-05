#!/bin/bash
openssl req -x509 -newkey rsa:2048 -keyout /heralding/key.pem -out /heralding/cert.pem -days 365 -nodes -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"

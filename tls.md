first stop the nomad service
```bash
sudo systemctl stop nomad
```
second use any cert creating app then add these certs in the /etc/certs folder 
ca.crt
nomad.crt
nomad.key

after adding the certs we have to give nomad the permission to access the file 
for that we use these commands 
```bash
sudo chown -R nomad:nomad /etc/certs
sudo cp /etc/certs/ca.crt /etc/pki/ca-trust/source/anchors/nomadkey.pem
sudo update-ca-trust extract
```

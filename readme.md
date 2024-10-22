-- First of we require server agents ( agent can be a server or a client )


-- Create a server nomad-agent-servera: t2.micro  
-- make sure to provide tags : 
   key=nomad_cluster_id value=us-east-1
-- Make sure to add role to the server for servers to have access to other servers or clients in ec2 service .. 
## installing nomad ##
Install nomad on it :
```bash
sudo apt-get update && sudo apt-get install wget gpg coreutils
wget -O- https://apt.releases.hashicorp.com/gpg |   sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install nomad
nomad version
nomad -h
cd /etc/nomad.d/
ls
```
-- delete the default .hcl file and replace it with basic-server.hcl config file ..
   -- inside the file make changes for ur local ip address of server , bootstrap_expect = 2 (or wtever no of servers wl b thr in cluster ) , tag value changes , etc ....
```bash
sudo rm -rf nomad.hcl
vi basic-server.hcl
sudo vi basic-server.hcl
ls
sudo systemctl start nomad 
sudo systemctl status nomad 
nomad server members 
```
====================

## NOMAD SERVER CLUSTERING : ##

-- create more ec2 instances with tags key=nomad_cluster_id value=us-east-1 , and role attached ,, also add the basic-server.hcl file(do the same cofig changes like in the frst one ) 
      and than restart the nomad service 
```bash    
nomad server members
```
-- as confirmed with above command now u ll be having ue server cluster setup doen :

ubuntu@ip-172-31-33-162:/etc/nomad.d$ nomad server members
Name                   Address        Port  Status  Leader  Raft Version  Build  Datacenter  Region
nomad_server_a.global  172.31.15.165  4648  alive   false   3             1.9.0  dc1         global
nomad_server_b.global  172.31.33.162  4648  alive   true    3             1.9.0  dc1         global
      

========================
## CLIENT-AGENT SETUP : ##



Now go ahead and create clients-agent nodes named : nomad-agent-clienta , nomad-agent-client b   or more if u want 
-- attach the ec2 admin role to client nodes as well 


follow prev steps with Basic-client. hcl like before ..

```bash
sudo apt-get update &&   sudo apt-get install wget gpg coreutils
wget -O- https://apt.releases.hashicorp.com/gpg |   sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install nomad
cd /etc/nomad.d/
ls
sudo rm -rf nomad.hcl 
vi basic-client.hcl
sudo vi basic-client.hcl
sudo systemctl start nomad 
ls
nomad server members
nomad node status
```
--- install docker as well on client nodes 

   https://docs.docker.com/engine/install/ubuntu/


  --- to reverify if all server members nd nodes joined or not :


ubuntu@ip-172-31-47-80:/etc/nomad.d$ nomad server members 
Name                   Address        Port  Status  Leader  Raft Version  Build  Datacenter  Region
nomad_server_a.global  172.31.15.165  4648  alive   false   3             1.9.0  dc1         global
nomad_server_b.global  172.31.33.162  4648  alive   true    3             1.9.0  dc1         global

ubuntu@ip-172-31-47-80:/etc/nomad.d$ nomad node status
ID        Node Pool  DC   Name            Class   Drain  Eligibility  Status
6a678df3  default    dc1  nomad_client_a  <none>  false  eligible     ready
0e39de68  default    dc1  nomad_client_b  <none>  false  eligible     ready


=========================================================================



u can browse over the ui s wel l : 

   http://54.207.4.129:4646/ui/servers


=========================================


remotel connect through cli :


-- install nomad , 

[cloudshell-user@ip-10-130-20-10 ~]$ export NOMAD_ADDR=http://15.228.254.41:4646
[cloudshell-user@ip-10-130-20-10 ~]$ nomad server members
Name                   Address        Port  Status  Leader  Raft Version  Build  Datacenter  Region
nomad_server_a.global  172.31.15.165  4648  alive   false   3             1.9.0  dc1         global
nomad_server_b.global  172.31.33.162  4648  alive   true    3             1.9.0  dc1         global


nomad job status

nomad node status

nomad agent-info


=====================================================

--- 
## Demo - Create a Job Specification : ##


tetris.nomad :    


ubuntu@ip-172-31-15-165:~$ cat tetris.nomad 
```hcl
job "tetris" {
  datacenters = ["dc1", "dc2"]

  group "games" {
    count = 3

    network {
      port "web" {
        to = 80
      }
    }

    task "tetris" {
      driver = "docker"

      config {
        image = "bsord/tetris"
        ports = ["web"]
      }
      resources {
        cpu    = 50
        memory = 50
      }
    }
  }
}
```



---
``` bash
pwd
vi tetris.nomad
nomad
nomad fmt
cat tetris.nomad 
vi tetris.nomad 
nomad job run tetris.nomad 
nomad job status 
nomad job status tetris
```


surf one of the tasks : http://54.233.4.142:24097/


==============================================================


-- job placemnt :

by default , its binpack .. to chnge it to spread  :




ubuntu@ip-172-31-15-165:~$ cat tetris.nomad 

```hcl
job "tetris" {
  datacenters = ["dc1"]

  group "games" {
    count = 15

    network {
      port "web" {
        to = 80
      }
    }
    spread {
       attribute = "${node.unique.id}"
           }
#https://developer.hashicorp.com/nomad/docs/runtime/interpolation#node-attributes

    task "tetris" {
      driver = "docker"

      config {
        image = "bsord/tetris"
        ports = ["web"]
      }
      resources {
        cpu    = 50
        memory = 50
      }
    }
  }
}

```
---
```bash
nomad job plan tetris.nomad 
nomad job run tetris.nomad 
```



-------------  stop and remove the tasks :


nomad job status
   90  nomad job stop
   91  nomad job stop tetris
   92  nomad job status
   93  nomad job status tetris
   95  nomad system gc 
   96  nomad job status tetris
   97  nomad job status

---- we can spread our tasks in diff az as per cloud env as well,...


check for the attribute from the ui relating to az s :

platform.aws.placement.availability-zone



ubuntu@ip-172-31-15-165:~$ cat tetris.nomad 
```hcl
job "tetris" {
  datacenters = ["dc1", "dc2"]

  group "games" {
    count = 15

    network {
      port "web" {
        to = 80
      }
    }
    spread {
       attribute = "${platform.aws.placement.availability-zone}"
       weight=100
       target"us-east-1c" {
             percent=100
            }
       target"us-east-1a" {
             percent=0
            }
           }

    task "tetris" {
      driver = "docker"

      config {
        image = "bsord/tetris"
        ports = ["web"]
      }
      resources {
        cpu    = 50
        memory = 50
      }
    }
  }
}


```
 nomad job plan tetris.nomad 
  102  nomad job run tetris.nomad 


---- reverify from the ui as well 
-- try to swtch over to other az as well

================================================================


## Using costraints : ##


--- add meta values in the client configurations in all clients :

--in first client clienta , update the meta stanza :

```hcl
 meta {
    team = "it-ops"
    env= "prod1"
    rack="rack12"
    hardware="cisco"
    instructor="raman"
  }
```

sudo systemctl restart nomad



--- in second client clientb , update the meta stanza :

```hcl
 meta {
    team = "it-ops"
    env= "prod2"
    rack="rack12"
    hardware="cisco"
    instructor="raman"
  }
```

sudo systemctl restart nomad


--- now add the constraints acc for env  in our tetris.nomad file :


ubuntu@ip-172-31-15-165:~$ cat tetris.nomad 
```hcl
job "tetris" {
  datacenters = ["dc1", "dc2"]

  group "games" {
    count = 15

    network {
      port "web" {
        to = 80
      }
    }

    constraint {
      attribute= "${meta.env}"
      value="prod1"
     }
    
    task "tetris" {
      driver = "docker"

      config {
        image = "bsord/tetris"
        ports = ["web"]
      }
      resources {
        cpu    = 50
        memory = 50
      }
    }
  }
}

```

nomad job run tetris.nomad 


--- now remove all tasks and try with env=prod2 or any other constraint :

```hcl
 constraint {
      attribute= "${meta.instructor}"
      value="raman"
     }
```

---
## Networking : ##

--by default nomad has host type mode , to change it to bridge we have to download cni plugins on our clients :


  nomad job status
  140  nomad job status tetris
  141  nomad system gc
  142  nomad job status tetris
  143  nomad alloc
  144  nomad alloc status 0ca67c20




-- go to clientnodes and check for below location

  146  cd /opt/bin
  147  cd /opt/cni/bin
  148  cd /opt/
  149  ls
  150  cd nomad/
  151  ls
  152  cd data/
  153  ls




--- install plugins on all clients : (ONLY ON CLIENTS )
https://developer.hashicorp.com/nomad/docs/install#install-cni-reference-plugins



export ARCH_CNI=$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)
export CNI_PLUGIN_VERSION=v1.5.1
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGIN_VERSION}/cni-plugins-linux-${ARCH_CNI}-${CNI_PLUGIN_VERSION}".tgz && \
  sudo mkdir -p /opt/cni/bin && \
  sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz



sudo systemctl restart nomad


------ add bridged mode to our nomad file on server :


 nomad job stop


  164  nomad stop job tetris
  165  nomad system gc
  166  cat tetris.nomad 



ubuntu@ip-172-31-15-165:~$ cat tetris.nomad 
```hcl
job "tetris" {
  datacenters = ["dc1", "dc2"]

  group "games" {
    count = 5

    network {
      mode="bridge"       #default: host
      port "web" {
        to = 80
      }
    }

    constraint {
      attribute= "${meta.instructor}"
      value="raman"
     }
    
    task "tetris" {
      driver = "docker"

      config {
        image = "bsord/tetris"
        ports = ["web"]
      }
      resources {
        cpu    = 50
        memory = 50
      }
    }
  }
}

```




  167  nomad run tetris.nomad 


--- verify the allocation now :

 nomad status job
  175  nomad job status
  176  nomad job status tetris
  177  nomad alloc status 0d3172aa

-- u will notice now it wl b deployed on host on a random port assigned by nomad 

    http://18.228.23.36:26559/   : try surfing on client node or pblicalyy 



==================


---
## Volumes :  ##

on both clients :
sudo mkdir /etc/nomad.d/volumes/scores01


--add a hostvol config first in clients nomad clientconfig file like below on the both clients  :



ubuntu@ip-172-31-15-106:~$ sudo cat /etc/nomad.d/basic-client.hcl
```hcl
# Basic Starter Configuration Used for Nomad Course Demonstrations
# This is NOT a Secure Complete Nomad Client Configuration

name = "nomad_client_b"

# Directory to store agent state
data_dir = "/etc/nomad.d/data"

# Address the Nomad agent should bing to for networking
# 0.0.0.0 is the default and results in using the default private network interface
# Any configurations under the addresses parameter will take precedence over this value
bind_addr = "0.0.0.0"

advertise {
  # Defaults to the first private IP address.
  http = "172.31.15.106" # must be reachable by Nomad CLI clients
  rpc  = "172.31.15.106" # must be reachable by Nomad client nodes
  serf = "172.31.15.106" # must be reachable by Nomad server nodes
}

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}

# TLS configurations
tls {
  http = false
  rpc  = false

  ca_file   = "/etc/certs/ca.crt"
  cert_file = "/etc/certs/nomad.crt"
  key_file  = "/etc/certs/nomad.key"
}

# Specify the datacenter the agent is a member of
datacenter = "dc1"

# Logging Configurations
log_level = "INFO"
log_file  = "/etc/nomad.d/raman.log"

# Server & Raft configuration
server {
  enabled = false
}

# Client Configuration
client {
  enabled = true

  server_join {
    retry_join = ["provider=aws tag_key=nomad_cluster_id tag_value=sa-east-1"]
  }
  host_volume "scores_volume" {
    path= "/etc/nomad.d/volumes/scores01"
    read_only= false
    }

  meta {
    team = "it-ops"
    env= "prod2"
    rack="rack12"
    hardware="cisco"
    instructor="raman"
  }
}
```






--- sudo systemctl restart nomad 


-- check the volume on the ui , now we have to mount our job on these host volume :

--- go to server agent node and update our tetris job to add the volume mount :





ubuntu@ip-172-31-15-165:~$ cat tetris.nomad 
```hcl
job "tetris" {
  datacenters = ["dc1", "dc2"]

  group "games" {
    count = 5

    network {
      mode="bridge"       #default: host
      port "web" {
        to = 80
      }
    }

    volume "scores" {
      type="host"
      read_only= false
      source="scores_volume"
      }

    task "tetris" {
      driver = "docker"

      config {
        image = "bsord/tetris"
        ports = ["web"]
      }
      
      volume_mount {
        volume= "scores"
        destination= "/var/lib/scores"
        read_only=false
      }

      resources {
        cpu    = 50
        memory = 50
      }
    }
  }
}
```



nomad job plan tetris.nomad 
nomad job plan tetris.nomad 

--check all pods will be deployed now on host volumes being persistent 


=============================================================

## -- NOMAD MONITORING: ##

  -- on wtever node  wnt to monitor /troubleshoot :

sudo systemctl status nomad

journalctl -u nomad    ( shift+G to go to end )

ubuntu@ip-172-31-47-80:~$ curl http://localhost:4646/v1/metrics | jq

cat /etc/nomad.d/raman.log


=======================================

## --Monitoring app logs : ##

 -- go to client lets say clienta to see the logs of our app :





sudo cat /etc/nomad.d/raman.log 
   85  clear
   86  ls
   87  cd /etc/nomad.d/
   88  ls
   89  cd data/
   94  sudo -i
 1  cd /etc/nomad.d/
    2  ls
    3  cd data/
    4  ls
    5  cd alloc/
    6  ls
    7  nomad job status
    8  nomad job status tetris
    9  nomad node status
   10  ls
   11  cd 454e46e1-3799-f787-9ede-e44b88787200/
   12  ls
   13  cd alloc/
   14  ls
   15  cd logs/
   16  ls
   17  cat tetris.stdout.0 
   18  ls
   19  cat tetris.stderr.0 


============================================


## NOMAD UPGRADE CLUSTER : ##


https://releases.hashicorp.com/nomad/



 nomad version
  289  sudo systemctl stop nomad
  290  cd /tmp/
  291  ls
  292  wget https://releases.hashicorp.com/nomad/1.9.1/nomad_1.9.1_linux_amd64.zip
  293  ls
  294  unzip nomad_1.9.1_linux_amd64.zip 
  295  sudo apt install unzip
  296  unzip nomad_1.9.1_linux_amd64.zip 
  297  ls
  298  which nomad
  299  ls /usr/bin/nomad
  300  rm -rf  /usr/bin/nomad
  301  sudo rm -rf  /usr/bin/nomad
  302  nomad
  303  ls
  304  mv nomad /usr/bin/
  305  sudo mv nomad /usr/bin/
  306  nomad
  307  nomad version
  308  sudo systemctl start nomad
  309  nomad server members
  310  nomad node status


==========================================================


## NOMAD ACLs : ##


-- go to server nodes to implement acl :

  -- sudo vi /etc/nomad.d/basic-server.hcl 



ubuntu@ip-172-31-15-165:~$ sudo cat /etc/nomad.d/basic-server.hcl 
```hcl
# Basic Starter Configuration Used for Nomad Course Demonstrations
# This is NOT a Secure Complete Nomad Server Configuration

name = "nomad_server_a"

# Directory to store agent state
data_dir = "/etc/nomad.d/data"

# Address the Nomad agent should bing to for networking
# 0.0.0.0 is the default and results in using the default private network interface
# Any configurations under the addresses parameter will take precedence over this value
bind_addr = "0.0.0.0"

advertise {
  # Defaults to the first private IP address.
  http = "172.31.15.165" # must be reachable by Nomad CLI clients
  rpc  = "172.31.15.165" # must be reachable by Nomad client nodes
  serf = "172.31.15.165" # must be reachable by Nomad server nodes
}

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}

# TLS configurations
tls {
  http = false
  rpc  = false

  ca_file   = "/etc/certs/ca.crt"
  cert_file = "/etc/certs/nomad.crt"
  key_file  = "/etc/certs/nomad.key"
}

# Specify the datacenter the agent is a member of
datacenter = "dc1"

# Logging Configurations
log_level = "INFO"
log_file  = "/etc/nomad.d/raman.log"

# Server & Raft configuration
server {
  enabled          = true
  bootstrap_expect = 2 

  server_join {
    retry_join = ["provider=aws tag_key=nomad_cluster_id tag_value=sa-east-1"]
  }
}

# Client Configuration - Node can be Server & Client
client {
  enabled = false
}


acl {
  enabled=true
   }

```


  




-- restart nomad service 

nomad status





ubuntu@ip-172-31-15-165:~$ nomad status
Error querying jobs: Unexpected response code: 403 (Permission denied)



ubuntu@ip-172-31-15-165:~$ nomad acl bootstrap
Accessor ID  = e2370171-b60e-36d9-60f2-f49f86012db0
Secret ID    = cd990dc2-0584-dbfa-d0b0-0d645579fbf3
Name         = Bootstrap Token
Type         = management
Global       = true





--- SecretId is our bootsptrap token ... (save it somewhere )


-- save the bootstrap token as an ebv variable ...

ubuntu@ip-172-31-15-165:~$ export NOMAD_TOKEN=cd990dc2-0584-dbfa-d0b0-0d645579fbf3


ubuntu@ip-172-31-15-165:~$ nomad status
ID      Type     Priority  Status   Submit Date
tetris  service  50        running  2024-10-21T13:12:25Z



ubuntu@ip-172-31-15-165:~$ unset NOMAD_TOKEN
ubuntu@ip-172-31-15-165:~$ nomad status
Error querying jobs: Unexpected response code: 403 (Permission denied)






=========================


-- ABOVE WAS  a management /bootstrap token having full access , to create a client toke with restrictive policy , below is an example for that :



-- Step 1: Create a Policy File


```hcl
namespace "default" {
  capabilities = ["submit-job", "read-logs", "alloc-exec", "scale-job"]
}

node {
  policy = "write"
}



namespace "web-app" {
  capabilities = ["submit-job", "read-logs", "alloc-exec", "scale-job"]
}

```








--  Step 2: Create the Policy in Nomad

```bash
 nomad acl policy apply restricted-policy restricted-policy.hcl
```
Successfully wrote "restricted-policy" ACL policy!


-- Step3 : Create a token that uses the policy:


```bash
nomad acl token create -name="restricted-client-token" -policy="restricted-policy"
```
Accessor ID  = 55a4fc96-3da7-b71a-50aa-aa5bc4c937cd
Secret ID    = 3e04823b-db05-362d-94cc-f290ec3d1eed
Name         = restricted-client-token
Type         = client
Global       = false
Create Time  = 2024-10-22 10:12:32.588016686 +0000 UTC
Expiry Time  = <none>
Create Index = 1661
Modify Index = 1661
Policies     = [restricted-policy]




--- to verify :

```bash
export NOMAD_TOKEN=3e04823b-db05-362d-94cc-f290ec3d1eed
```


Step 1: Verify Permissions with Commands
The current policy grants the following capabilities:

submit-job, read-logs, alloc-exec, and scale-job in both default and web-app namespaces.
Write access to nodes.



===========================================================================




====================================================


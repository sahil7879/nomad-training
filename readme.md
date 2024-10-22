-- First of we require server agents ( agent can be a server or a client )


-- Create a server nomad-agent-servera: t2.micro  
-- make sure to provide tags : 
   key=nomad_cluster_id value=us-east-1
-- Make sure to add role to the server for servers to have access to other servers or clients in ec2 service .. 

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

NOMAD SERVER CLUSTERING :

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

CLIENT-AGENT SETUP :



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

---  Demo - Create a Job Specification :


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


Using costraints :


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




====================================================


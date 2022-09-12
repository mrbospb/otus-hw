# Description
Vagrant creates 2 VM's (server and client) with NFS folder `/srv/nfs/upload/`

# How-to
Use `vagrant up` to start VM's

### Get names/id of the machines
```
bo@vivobo:~/otus/otus-hw/hw05$ vagrant global-status
id       name       provider   state   directory                           
---------------------------------------------------------------------------
19b5509  lvm        virtualbox running /home/bo/otus/otus-hw/hw03          
4914b76  serverhw04 virtualbox running /home/bo/otus/otus-hw/hw04          
aa3ab27  server     virtualbox running /home/bo/otus/otus-hw/hw05          
4382cca  client     virtualbox running /home/bo/otus/otus-hw/hw05          
 
The above shows information about all known Vagrant environments
on this machine. This data is cached and may not be completely
up-to-date (use "vagrant global-status --prune" to prune invalid
entries). To interact with any of the machines, you can go to that
directory and run Vagrant, or you can use the ID directly with
Vagrant commands from any directory. For example:
"vagrant destroy 1a2b3c4d"
```

### Create a test file
```
bo@vivobo:~/otus/otus-hw/hw05$ vagrant ssh server
Last login: Mon Sep 12 14:30:26 2022 from 10.0.2.2
[vagrant@hw05-server ~]$ echo "A file from server" > /srv/nfs/upload/nfs-share-example
[vagrant@hw05-server ~]$ cat /srv/nfs/upload/nfs-share-example
A file from server
```

### Check if test file can be read from the client machine
```
[vagrant@hw05-server ~]$ exit
logout
bo@vivobo:~/otus/otus-hw/hw05$ vagrant ssh client
Last login: Mon Sep 12 14:29:15 2022 from 10.0.2.2
[vagrant@hw05-client ~]$ cat /mnt/upload/nfs-share-example 
A file from server
```
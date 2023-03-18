# csp-log-tutorial

## Prerequisites
Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) installed.

I created a git folder inside the IRIS mgr directory. I right clicked the git folder and chose Git Bash Here from the context menu.

I will describe in this tutorial how I try to use access.log and CSP.log files in webgateway pods to track requests and responses.

My team works with IRIS containers running on Red Hat OpenShift Container Platform (Kubernetes) in AWS. We deployed three webgateway pods receiving requests via a Network Load Balancer. The requests get processed in an InterOperability production running in three compute pods. We use Message Bank production running on mirrored data pods as one place to review all messages processed by any compute pod.

We tested our interfaces using feeder pods to send many request messages to the Network Load Balancer. We sent 100k messages and tested how long it would take to process all messages into the message bank and record the responses on the feeders. The count of banked messages in Message Bank and responses received by the feeders matched the number of incoming messages.

Recently we were asked to test pods failovers and Availability Zone fail-over. We simulate an availability zone failure by denying all incoming and outgoing traffic to a subnet (one of three availability zones) via the AWS console while feeders are sending many request messages to the Network Load Balancer. It has been quite challenging to account for all messages sent by the feeders.

The other day while one feeder sent 5000 messages, we simulated the AZ failure. The feeder received 4933 responses. The message bank banked 4937 messages.

We store access.log and CSP.log in the data directory on the webgateway pods. We added this line to the Dockerfile of our webgateway image:

```
RUN sed -i 's|APACHE_LOG_DIR=/var/log/apache2|APACHE_LOG_DIR=/irissys/data/webgateway|g' /etc/apache2/envvars
```

We set the Event Log Level in Web Gateway to Ev9r.
![screenshot](https://github.com/oliverwilms/bilder/blob/main/wgw.png)

I created data0, data1, and data2 subdirectories for our three webgateway pods. I copy the CSP.log and access.log files from our three webgateway pods stored on persistent volumes:
```
oc cp iris-webgateway-0:/irissys/data/webgateway/access.log data0/access.log
oc cp iris-webgateway-1:/irissys/data/webgateway/access.log data1/access.log
oc cp iris-webgateway-2:/irissys/data/webgateway/access.log data2/access.log
oc cp iris-webgateway-0:/irissys/data/webgateway/CSP.log data0/CSP.log
oc cp iris-webgateway-1:/irissys/data/webgateway/CSP.log data1/CSP.log
oc cp iris-webgateway-2:/irissys/data/webgateway/CSP.log data2/CSP.log
```

I end up with three subdirectories each containing access.log and CSP.log files.

We count the number of requests processed in any webgateway pod using this command:
```
cat access.log | grep InComingOTW | wc -l
```

We count the number of requests and responses recorded in CSP.log using this command:
```
cat CSP.log | grep InComingOTW | wc -l
```

Normally we expect twice as many lines in CSP.log compared to access.log. Sometimes we find more lines in CSP.log than the expected double the number of lines in access.log. I remember seeing less lines than expected in CSP.log compared to what was in access.log at least once. We suspect this was due to a 500 response recorded in access.log, which was not recorded in CSP.log, properly because the webgateway pod was terminated.

How can I analyze many lines of requests and explain what happened?

I created persistent classes otw.wgw.apache and otw.wgw.csp to import lines from access.log and CSP.log. access.log contains one line per request and it includes the response status. CSP.log contains separate lines for requests and responses.

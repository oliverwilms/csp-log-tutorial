# csp-log-tutorial

## Prerequisites
Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) installed.

I will describe in this tutorial how I use access.log and CSP.log files in webgateway pods to track requests and responses.

My team works with IRIS containers running on Red Hat OpenShift Container Platform (Kubernetes) in AWS. We deployed three webgateway pods receiving requests via a Network Load Balancer. The requests get processed in an InterOperability production running in three compute pods. We use Message Bank production running on mirrored data pods as one place to review all messages processed by any compute pod.

We tested our interfaces using feeder pods to send many request messages to the Network Load Balancer. We sent 100k messages and tested how long it would take to process all messages into the message bank and record the responses on the feeders. The count of banked messages in Message Bank and responses received by the feeders matched the number of incoming messages.

Recently we were asked to test pods failovers and Availability Zone fail-over. We simulate an availability zone failure by denying all incoming and outgoing traffic to a subnet (one of three availability zones) via the AWS console while feeders are sending many request messages to the Network Load Balancer. It has been quite challenging to account for all messages sent by the feeders.

The other day while one feeder sent 5000 messages, we simulated the AZ failure. The feeder received 4933 responses. The message bank banked 4937 messages.

We store access.log and CSP.log in the data directory on the webgateway pods. We added this line to the Dockerfile of our webgateway image:

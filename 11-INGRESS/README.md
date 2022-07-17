## Objetivos de aprendizaje

By the end of this chapter, you should be able to:

- Discuss the difference between an Ingress Controller and a Service.​
- Learn about nginx and GCE Ingress Controllers.
- Deploy an Ingress Controller.
- Configure an Ingress Rule.

## Overview

In an earlier chapter, we learned about using a Service to expose a containerized application outside of the cluster. We use Ingress Controllers and Rules to do the same function. The difference is efficiency. Instead of using lots of services, such as LoadBalancer, you can route traffic based on the request host or path. This allows for centralization of many services to a single point. 
An Ingress Controller is different than most controllers, as it does not run as part of the kube-controller-manager binary. You can deploy multiple controllers, each with unique configurations. A controller uses Ingress Rules to handle traffic to and from outside the cluster. 
There are many ingress controllers such as GKE, nginx, Traefik, Contour and Envoy to name a few. Any tool capable of reverse proxy should work. These agents consume rules and listen for associated traffic. An Ingress Rule is an API resource that you can create with kubectl. When you create that resource, it reprograms and reconfigures your Ingress Controller to allow traffic to flow from the outside to an internal service. You can leave a service as a ClusterIP type and define how the traffic gets routed to that internal service using an Ingress Rule.


# Ingress Controller
An Ingress Controller is a daemon running in a Pod which watches the /ingresses endpoint on the API server, which is found under the networking.k8s.io/v1beta1 group for new objects. When a new endpoint is created, the daemon uses the configured set of rules to allow inbound connection to a service, most often HTTP traffic. This allows easy access to a service through an edge router to Pods, regardless of where the Pod is deployed. 

Multiple Ingress Controllers can be deployed. Traffic should use annotations to select the proper controller. The lack of a matching annotation will cause every controller to attempt to satisfy the ingress traffic.


[The Ingress Controller for Inbound Connections]()

The Ingress Controller for Inbound Connections



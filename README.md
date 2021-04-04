## cnvrg-core
resources for deploying and using cnvrg CORE 

- To install on a linux machine in any environment


```

# example ./cnvrg-setup-headless.sh 11.22.33.44
./cnvrg-setup-headless.sh public.ip.of.machine

```

- To creat an AWS AMI with minikube and deploy cnvrg automatically 

*** if you have a prefered key copy it into the cnvrg-core/cnvrg-aws directory before running ./aws-automation.sh... 

cd into the cnvrg-aws directory 
```
git clone https://github.com/vvagias/cnvrg-core.git
cd cnvrg-core/cnvrg-aws/
./aws-automation.sh
#enter options at the prompts
```

*** If after the install finishes you see "no healthy upstream" you may just need to wait several minutes. issues with network speeds and install times as well as service health checks may cause the install to take longer. 

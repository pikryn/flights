FROM centos

RUN yum install -y epel-release 
RUN yum update -y 
RUN yum install -y R
RUN yum -y install R

RUN yum -y install libxml2-devel
RUN yum -y install curl-devel
RUN yum -y install openssl-devel

ADD install.R /
RUN Rscript /install.R 
ADD flights.R /
ADD opisy /opisy/
VOLUME /loty_dane
CMD Rscript /flights.R small

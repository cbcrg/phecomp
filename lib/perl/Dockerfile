FROM perl:threaded-buster
LABEL authors="Jose Espinosa-Carrasco" \
    description="Docker image containing all software requirements for phecomp analysis"

# RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install DateTime; install HTTP::Date'
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install DateTime'
RUN PERL_MM_USE_DEFAULT=1 cpanm HTTP::Date
RUN PERL_MM_USE_DEFAULT=1 cpanm DateTime::Format::Strptime

# COPY mtb2int.pl int2combo.pl tac2pos ./

COPY tac2pos mtb2int.pl int2combo.pl /opt/phecomp/bin/

ENV PATH=$PATH:/opt/phecomp/bin

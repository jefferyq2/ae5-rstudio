FROM leader.telekube.local:5000/ae-editor:5.3.1-22.g6cafcc9c5
COPY . /aesrc/rstudio/
RUN cd /aesrc/rstudio && bash install_rstudio.sh

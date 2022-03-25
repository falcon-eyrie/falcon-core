![Falcon version](https://img.shields.io/badge/Falcon-v1.3.0-blue)

# Falcon core

Falcon is a software for real-time processing of neural signals to enable short-latency closed-loop feedback in 
experiments that try to causally link neural activity to behavior. 
 
Example use cases are the detection of hippocampal ripple oscillations or online decoding and detection of hippocampal replay patterns.
The full documentation can be found [here!](https://falcon-core.readthedocs.io)

It is based on a graph definition composed with processors chose to accomplish a specific task and connections between them. 
However, processors are managed separate repositories as extensions.

When building the falcon project with the default extension setting (see extensions.txt), it will add by default the falcon-fklab-extension.
See extensions documentation [here!](https://falcon-fklab-extensions.readthedocs.io)

Don't hesitate to personalize Falcon with your own set of extensions.

## Contribution 

If your issue concerned the installation or falcon during running time, don't hesitate to add an issue 
describing the problem / or the feature to develop. Add the graph (+ eventually the config file) used to run Falcon
is highly recommended. 
 
To develop a new extension, an issue can be open here for guidance but most probably the maintainer will advise you to 
create your own repository and then open an PR in Falcon to link your extension doc in the Falcon doc. 

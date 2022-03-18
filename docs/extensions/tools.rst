Add Tools and Resources in an extension
=======================================

Tools are separable executable built at the same time of falcon-core. For example, the core extension is providing
two tools :

- NlxTestBench : generate input signals to use in test mode the neuralynx reader processors.
- FilterTest : allow to examine and re-create new filters to be use in the multichannelfilter processor.

Resources are a separable folder in each extension which will be combine in only one after build and added in the share
folder of the installation. Falcon has some URI path setup to this resource folder =

- resources://path = resources/path
- graphs://path = resources/graphs/path
- filters://path = resource/filters/path

You can also add your own folder in the resources folder with your own URI.

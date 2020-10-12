# OpenASSA - POC1_Divan

openASSA is an initiative by members of the Actuarial Society of South Africa to develop open-source actuarial software. The project is still very new and the design and goals are currently being discussed.

If you're interested in joining the discussion, please join our [Slack channel](https://communityinviter.com/apps/openassa/openassa).

Please note **this is work in progress for OpenASSA's poc.**

It is an attempt using python to create an understanding and visibility about OpenASSA's vision.

## Getting Started

This program uses python to produce cash flows for a simple life insurance product and present values the cash flows to get a reserve amount.

It uses customer accessor on pandas to add customer methods to standardize and validate input data. It then uses common custom calculations to apply to a dataframe.

It also demonstrates how to package the solution into a class structure which can be expanded for more complicated products.

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites
We will need a python environment to use this application. For this packaged solution conda or miniconda can be installed as per the instructions in this [link](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html).

Alternatively, we can install python directly as show in this [link](https://realpython.com/installing-python/#step-1-download-the-python-3-installer) and then, use venv module to create an environment as shown in this [link](https://realpython.com/python-virtual-environments-a-primer/).


### Installing

Update conda to python 3.8 and create a separate environment.

```
conda install -c anaconda python=3.8
conda update --all
conda create -n assa python=3.8
conda activate assa
```

Then, install dependencies.
```
conda install flask pandas xlrd
```


### Break down into end to end tests

Explain what these tests test and why

```
***
```

### And coding style tests

Explain what these tests test and why

```
***
```

## Deployment

Open Jupyter notebooks, open the file openASSA POC.ipynb and run the code.

## Built With

* [***](***) - ***
* [***](***) - ***
* [***](***) - ***

## Contributing

Please read [CONTRIBUTING.md](***) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [***](***) for versioning. For the versions available, see the [tags on this repository](https://github.com/openASSA/openASSA/tags).

## Authors

* ***

## Contributors

List of [contributors](https://github.com/openASSA/openASSA/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* **Billie Thompson** - *For providing this template for Readme.md* - [PurpleBooth](https://github.com/PurpleBooth)

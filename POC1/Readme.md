# OpenASSA - POC1

openASSA is an initiative by members of the Actuarial Society of South Africa to develop open-source actuarial software. The project is still very new and the design and goals are currently being discussed.

If you're interested in joining the discussion, please join our [Slack channel](https://communityinviter.com/apps/openassa/openassa).

Please note **this is work in progress for OpenASSA's poc.**

It is a 1st attempt using basic python stack to create an understanding and visibility about OpenASSA's vision.

## Getting Started

It uses pandas, eval, flask and bootstrap to create a (dev server based) web page.
It will be mainly based on rules-engine, which will need a parser to be developed.
Currently, it is built with Python's eval function and uses hard-coded rules for now, but, it can be enhanced to parse rules based on MS Excel like syntax.
Pandas is mainly used for dataframe, to read excel file and to convert to html.

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites
We will need a python environment to use this application. For this packaged solution conda or miniconda can be installed as per the instructions in this [link](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html).

Alternatively, we can install python directly as show in this [link](https://realpython.com/installing-python/#step-1-download-the-python-3-installer) and then, use venv module to create an environment as shown in this [link](https://realpython.com/python-virtual-environments-a-primer/).

Also, to view the output of this application, we will need a browser which supports javascript.

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

Open a terminal, go to the path/folder where this repository is pulled or copied and then, use below command to execute it.

```
python assa_poc.py runserver
```

Once it is ready, it will show below command, then click on this link to see the output.
Later, after closing browser page, use CTRL + C to quit.

```
Running on http://127.0.0.1:5000/ (Press CTRL+C to quit)
```

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

> Use simple random sampling to select respondents from a list

To use the sampling tool you will need a data set with a variable of type character. Entries should be unique (i.e., no duplicates). A dataset that fits these requirements is bundled with Radiant. On the Data > Manage tab click the examples radio button and then click `Load examples`. Select `rndnames` from the `Datasets` dropdown.

`Names` is the relevant column in this dataset and it will automatically be used as the base for sampling. Now simply choose the sample size you want and a list of names of the desired length will be created.

How does it work? Each person in the data is assigned a random number between 0 and 1 from a uniform distribution. Rows are then sorted on that random number and the $n$ people from the list with the highest score are selected for the sample. By using a random number every respondent has the same probability of being in the sample. For example, if we need a sample of 10 people from the 100 included in the rndnames dataset each individual has a 10% chances of being included in the sample. By default, no random seed is set. To ensure the sampling results are reproducible, enter a number in the `Rnd. seed` input.

<p align="center"><img src="figures_design/sampling.png"></p>

The full list of 100 people is the `sampling frame`. Ideally, this is a comprehensive list of _all_ sampling units (e.g., customers or companies) in your target market.

How do you determine the appropriate value for _n_? Use the sample size tools in the _Design_ menu.

### Report > Rmd

Add code to <a href="https://radiant-rstats.github.io/docs/data/report.html" target="_blank">_Report > Rmd_</a> to (re)create the sample by clicking the <i title="report results" class="fa fa-edit"></i> icon on the bottom left of your screen or by pressing `ALT-enter` on your keyboard. 

# kubernetes

## Shell setup

- Use the [bashrc_append.sh](bashrc_append.sh) script to append to the ~/.bashrc file
  - `git clone https://github.com/glahitette/kubernetes && cd kubernetes && chmod +x bashrc_append.sh && cp $HOME/.bashrc $HOME/.bashrc_backup && ./bashrc_append.sh`

## Pasting text (e.g. YAML file content) without loosing indentation

Per [Vi Bracketed Pasting](https://www.baeldung.com/linux/vi-indenting#vi-bracketed-pasting), use:
- `:set paste` to disable dangerous functions like automatic indentation while pasting
- `:set nopaste` to restore the initial settings 
- `:set pastetoggle=<F10>` to map a key (e.g. F10) to toggle the paste mode

[//]: # From A Cloud Guru training: 
[//]: # (&#40;Note: When copying and pasting code into Vim from the lab guide, first enter :set paste &#40;and then i to enter insert mode&#41; to avoid adding unnecessary spaces and hashes.&#41;)

[//]: # (Effectively, vi adds the necessary escape characters to bracket the new content and does not interpret anything within:)

## Certification

- Are candidates monitored?
- Can we use the Internet / Google / OpenAI?
- Can we install packages (as sudo)?
- Can we use git clone (to quickly setup my env...and access sample yaml files)?

# kubernetes

## Shell setup

- Use the [.bashrc](.bashrc_from_killercoda.com) example from killercoda.com, in particular:

```
echo "alias h=history" >> ~/.bashrc 
echo "alias k=kubectl" >> ~/.bashrc 
echo "source /etc/bash_completion" >> ~/.bashrc 
echo "source <(kubectl completion bash)" >> ~/.bashrc 
echo "complete -F __start_kubectl k" >> ~/.bashrc
echo "export do='--dry-run=client -o yaml'" >> ~/.bashrc
echo "export now='--force --grace-period 0'" >> ~/.bashrc
bash
```

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

# Justfile

The `Justfile` is a file that contains the recipes for the project.

It's like `Makefile` but ~~better~~ newer and this seemed like a good opportunity to try it out.

To run a recipe, use the `just` command.

```
just <recipe>
```

To list all the recipes, use the `just` command without any arguments.

```
just
```

## Verdict

After using `just` on this project for a few days... I like it.

It feels more intuitive than Makefile.

However I did not like the way the dotenv file was loaded. I had to use `export $(grep -v '^#' .env | xargs -d '\n')` to load the variables into the shell for it to pick up variables created within the same execution of the `just` command.

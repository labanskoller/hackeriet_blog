---
layout: post
title: "How we did translations in Rust for Ripasso"
author: capitol
category: infrastructure
---
![rust-loop](/images/rust-loop.jpg)

One core principle of writing user friendly software is that the software should adapt
to the user, not the user to the software. A user shouldn't need to learn a new language
in order to use the software for example.

Therefore internationalization is a usability feature that we shouldn't ignore.

There exists a number of frameworks for translations, but GNU Gettext is one of the most used.
So that is what we will use also.

Solving that problem requires solving a few sub-problems:

 * Extracting strings to translate from the source code
 * Updating old translation files with new strings
 * Generating the binary translation files
 * Using the correct generated translation

## Extracting translatable strings from Rust source code

The Gettext package contains a number of helper programs, among them `xgettext` which can be used
to extract the strings from the Rust sources.

One drawback is that Rust isn't on the list of languages that xgettext can parse. But Rust is similar
enough to C so that we can use that parser, as long as we don't have any multiline strings.

In [Ripasso](https://github.com/cortex/ripasso) we extract it like this:

```bash
xgettext cursive/src/*rs -kgettext --sort-output -o cursive/res/ripasso-cursive.pot
```

## Updating old translation files with new strings

This isn't Rust specific in any way, but needs to be done so we include it as a step. We use the Gettext
program `msgmerge`:

```bash
msgmerge --update cursive/res/sv.po cursive/res/ripasso-cursive.pot
```

The .pot file is the template file that contains all the strings, and there will be one .po per language
that contains the translations for that language.

A translator can open the .po file in a translation program, for example [poedit](https://poedit.net/)
and translate it.

## Generating the binary translation files

We do this with a third utility program from Gettext, called `msgfmt`, called from build.rs. It reads
the .po files and generates binary .mo files.

This code from Ripasso is a bit verbose/ugly, but it gets the job done.

```rust
fn generate_translation_files() {
    let mut dest_path = std::env::current_exe().unwrap();
    dest_path.pop();
    dest_path.pop();
    dest_path.pop();
    dest_path.pop();
    dest_path.push("translations");
    print!("creating directory: {:?} ", &dest_path);
    let res = std::fs::create_dir(&dest_path);
    if res.is_ok() {
        println!("success");
    } else {
        println!("error: {:?}", res.err().unwrap());
    }
    dest_path.push("cursive");
    print!("creating directory: {:?} ", &dest_path);
    let res = std::fs::create_dir(&dest_path);
    if res.is_ok() {
        println!("success");
    } else {
        println!("error: {:?}", res.err().unwrap());
    }

    let mut dir = std::env::current_exe().unwrap();
    dir.pop();
    dir.pop();
    dir.pop();
    dir.pop();
    dir.pop();
    dir.push("cursive");
    dir.push("res");

    let translation_path_glob = dir.join("**/*.po");
    let existing_iter =
        glob::glob(&translation_path_glob.to_string_lossy()).unwrap();

    for existing_file in existing_iter {
        let file = existing_file.unwrap();
        let mut filename =
            format!("{}", file.file_name().unwrap().to_str().unwrap());
        filename.replace_range(3..4, "m");

        print!(
            "generating .mo file for {:?} to {}/{} ",
            &file,
            dest_path.display(),
            &filename
        );
        let res = Command::new("msgfmt")
            .arg(format!(
                "--output-file={}/{}",
                dest_path.display(),
                &filename
            ))
            .arg(format!("{}", &file.display()))
            .output();

        if res.is_ok() {
            println!("success");
        } else {
            println!("error: {:?}", res.err().unwrap());
        }
    }
}
```

The .mo files will end up in `target/translations/cursive/`, one file per language.

## Using the correct generated translation

The best crate I found was [gettext](https://crates.io/crates/gettext). There were also others
but they required unstable Rust features and was therefore unusable. Since the various Linux
distributions use the stable Rust to compile their packages.

During runtime, the translations live inside a lazy_static variable:

```rust
lazy_static! {
    static ref CATALOG: gettext::Catalog = get_translation_catalog();
}
```

But getting the correct translation into that variable can be a bit tricky. Here is how we do it
in Ripasso:

```rust
fn get_translation_catalog() -> gettext::Catalog {
    let locale = locale_config::Locale::current();

    let mut translation_locations = vec!["/usr/share/ripasso"];
    if let Some(path) = option_env!("TRANSLATION_INPUT_PATH") {
        translation_locations.insert(0, path);
    }
    if cfg!(debug_assertions) {
        translation_locations.insert(0, "./cursive/res");
    }

    for preferred in locale.tags_for("messages") {
        for loc in &translation_locations {
            let langid_res: Result<LanguageIdentifier, _> =
                format!("{}", preferred).parse();

            if let Ok(langid) = langid_res {
                let file = std::fs::File::open(format!(
                    "{}/{}.mo",
                    loc,
                    langid.get_language()
                ));
                if let Ok(file) = file {
                    if let Ok(catalog) = gettext::Catalog::parse(file) {
                        return catalog;
                    }
                }
            }
        }
    }

    gettext::Catalog::empty()
}
```

A few things needs explaining. First about the paths, `/usr/share/ripasso` is the default and always
a place where we search for translation files. The `option_env!` macro is there so that different
distributions can specify their own paths during compile time. The check `cfg!(debug_assertions)`
is true when running in debug mode, and is there so that it's easy to test a translation while you
are working on it.

The for loop selects the most fitting language based on how the user have configured their locale.

If none of those match the languages that we have available, we return an empty Catalog, which means
that it defaults back to english.

## Conclusion

Translating Rust programs isn't as straight forward as it could be, but it's in no way impossible
and well worth doing.

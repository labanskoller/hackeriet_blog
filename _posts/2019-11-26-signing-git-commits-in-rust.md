---
layout: post
title: "Signing git commits in Rust"
author: capitol
category: infrastructure
---
![rust-sign](/images/rust-sign.jpg)

This weekend I managed to get my rust code to produce signed gpg commits, and since
that wasn't trivial I thought I should do a small writeup about it.

## Why sign your git commits?

Since git is a distributed version control system, there is no central point of authority
that will control what you write in the `committer` field. One way to reduce the attack surface
is to sign your commits with your gpg key. That way a bad actor needs to steal both your
gpg key and gain write access to the repository in order to impersonate you.

## What is actually being signed?

We don't sign the actual bytes that make up the commit inside the git data structure, but
rather a text representation of the commit, which looks like this:

```text
tree 996fdae121be5db0fad96f3f9a82bec92109acd4
parent 509d883c16dbb7f48b949457cdee0d74ab01a5d3
author Alexander Kjäll <alexander.kjall@gmail.com> 1574528313 +0100
committer Alexander Kjäll <alexander.kjall@gmail.com> 1574528313 +0100
```

Signing that with gpg produces another text blob which you can add to the git commit.

```text
-----BEGIN PGP SIGNATURE-----

iQEzBAABCgAdFiEE2wfaxbOILqtlnh0v3ww9MWtzEtUFAl3ZZTkACgkQ3ww9MWtz
EtVgJAf+Mc7tiacLOIZHasjKX/Rcar24YT4J4Qam6cL2vPQI2tA1GQJpe2PgPZqF
JPIEXVqKWPFVUOqK0Bwr2RDNVIedxeRQ48qWA/mGX0/cY6yK+Jb1pVOPLMjhCMfs
ONmsCUi5mcn6cKdNp+jauAUQ1j2QzbcUHWFNnQHTblJUTZD73eUGg/clQ0sGk6A1
MR9zvRB8Y5ZBvb9eW5PS9+Wcex6awmrtS1Qz4mTOq2NNqIH54b/TMqJ1BpxXJ+HF
s0GCr32hSdjmnjCLeiAdtjItrjMrwBEfUolgvT5InzYXT2v5Do/wMPK0wRtzGf3i
Ykvq7e6qb0Q6wgtQ0t0R0PYZFZiZCA==
=OU7K
-----END PGP SIGNATURE-----
```

## How to tell git to sign commits?

Communicating to git that you want to sign your commits with gpg is done with two configuration
parameters. A boolean `commit.gpgsign` which determines if you want to sign it at all and a string
`user.signingkey` that contains the keyid of the gpg key to sign with.

Those are easily read in rust like this:

```rust
let config = git2::Config::open_default()?;

let signing_key = config.get_string("user.signingkey")?;
```

### What does the code look like?

I use the excellent [git2](https://docs.rs/git2/) library, rust bindings for
the [libgit2](https://libgit2.org/) library, which is one of the libraries that powers GitHub.

The two most important functions are [commit_create_buffer](https://docs.rs/git2/0.10.2/git2/struct.Repository.html#method.commit_create_buffer) 
and [commit_signed](https://docs.rs/git2/0.10.2/git2/struct.Repository.html#method.commit_signed).
The first one produces the text representation of the commit, and the second does the actual commit
to disk.

The rust code looks like this:

```rust
let commit_buf = (*repo_opt).as_ref().unwrap().commit_create_buffer(
    &signature, // author
    &signature, // committer
    message, // commit message
    &tree, // tree
    &parents)?; // parents

let commit_as_str = str::from_utf8(&commit_buf).unwrap().to_string();

let sig = gpg_sign_string(&commit_as_str)?;

let commit = (*repo_opt).as_ref().unwrap().commit_signed(&commit_as_str, &sig, Some("gpgsig"));
```

Where `gpg_sign_string` is my own function that handles the gpg signing business.

And that leads us to the gpg situation.

### Signing a string with gpgme

I used the [gpgme](https://docs.rs/crate/gpgme/0.9.1) library, and that isn't a very nice library
to work with, it gets the job done, but it has some nasty pitfalls.

The code ended up like this:

```rust
pub fn gpg_sign_string(commit: &String) -> Result<String> {
    let config = git2::Config::open_default()?;

    let signing_key = config.get_string("user.signingkey")?;

    let mut ctx = gpgme::Context::from_protocol(gpgme::Protocol::OpenPgp)?;
    ctx.set_armor(true);
    let key = ctx.get_secret_key(signing_key)?;

    ctx.add_signer(&key)?;
    let mut output = Vec::new();
    let signature = ctx.sign_detached(commit.clone(), &mut output);

    if signature.is_err() {
        return Err(Error::GPG(signature.unwrap_err()));
    }

    return Ok(String::from_utf8(output)?);
}
```

And the API has some design problems that makes it harder than necessary to use:

 * The `sign_detached` method returns its output in the `Vec` that you supply as the second argument
   instead of simply returning it.
 * If you forget the `mut` modifier on the argument to the `sign_detached` method, the
   code compiles without problem, and you get this runtime error: `Bad file descriptor (gpg error 32779)`.
   That really doesn't help explaining what's going on at all.

But aside from those gripes, it gets the job done.

I hope I will have time to investigate the new openpgp library
[sequoia](https://sequoia-pgp.org/) in the future. It looks like it might be a good replacement.

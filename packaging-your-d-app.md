## Title
Packaging your D app

## Kind
Talk

## Duration
~30 minutes

## Target audience
beginner/intermediate

## Abstract
You’ve developed your app in D, now how to get it into people’s hands? In this talk I will cover several packaging methods for your CLI or web app.

## Keywords
package dependencies docker container deployment release

## Biography
Lionello Lunesu is creator of Nounly and Co-Founder of Enuma Technologies, a hardware/software consultancy company in Hong Kong, building solutions for enterprise customers. Nounly started as a weekend project, but turned into a web app people started to rely on. To meet expectations, Nounly was ported to Vibe.D and is now hosted as an auto-scaling web service.

## Extended description
One of the harder problems is how to manage dependencies, not just during development in a team where people have different
operating systems, but also during deployment in the cloud or customer's environment. So how can you build a package that Just Runs™ wherever it's run?

DUB is a great package manager and build tool for D, but does little to help you build the final package for deployment. Different operating systems each have their own popular package format. In the past I’ve created DEB and RPM packages for my D apps, but more recently created Nix packages and/or Docker containers. Needless to say, DEB and RPM only work on specific Linux distros, though more recently Snap, AppImage, and Flatpak are each trying to become the package format for all Linux distros. Nix on the other hand is a great tool for managing dependencies and creating a platform agnostic package that works on both Linux and MacOS and can also be used to create minimal Docker containers. Docker itself is of course the most popular container format and a great way to package an application with all its dependencies, either for testing or deployment as a cloud service.

### Docker
Creating a Docker container, whether for testing or deployments, is as easy as creating a `Dockerfile` that adds all binaries and any dependencies and assets to the container.

Here's a minimal example for a D program called `hello.d`:
```d
import std.stdio;
void main() {
  writeln("Hello world");
}
```

```docker
FROM dlanguage/dmd
COPY hello.d .
RUN dmd -of=hello hello.d
CMD ["./hello"]
```

There are a few problems with this simple approach:
 * Pre-built, published docker images like `dlanguage/dmd` contain many preinstalled programs, resulting in larger containers with bigger attack surface.
 * Ensuring that the container contains all required dependencies often involves a lot of trial and error.
 * Any added binaries must have been built using the same build environment that the container is using at runtime. This includes any dependencies provided by the underlying OS image.
 * Building a Docker container on MacOS results in a container that can only be used on MacOS, making it unsuitable for deployments.

These issues are addressed by using a multi-stage build. Here I'm using *dockerize* to copy the executable, and all its dependencies into an output folder:
```docker
FROM dlanguage/dmd AS build-stage
RUN apt-get update && apt-get -y install \
        git \
        python-setuptools
# Install dockerize from GIT (or copy from local submodule)
RUN git clone --depth=1 https://github.com/larsks/dockerize.git
WORKDIR dockerize
RUN python setup.py install

WORKDIR /
COPY hello.d .
RUN dmd -of=hello hello.d
RUN dockerize -o /output -n /hello

FROM scratch
COPY --from=build-stage /hello /
CMD ["./hello"]
```

Our container can now be uploaded to Docker hub for others to use:
```sh
docker build . --tags lionello/hellod
docker push lionello/hellod
```

### Nix
It's worth explaining a bit about what Nix is and isn't. Nix is foremost a package manager, but is also the name of the language in which these packages are written. The Nix language is functional and declarative, with each package (a *derivation*) precisely describing what its dependencies and sources (the *inputs*) are and how it must be built. When a package is requested, the Nix package manager will find the package's derivation and evaluate it, resulting in the recursive evaluation of all its dependencies. Each step will result in a derivation that's installed in a unique folder in the global Nix store at `/nix/store`, with the name of the folder based on the hash of all the package's inputs, not just its name or semantic version!

In Nix, a common post-build step is replacing all relative dependency paths (like dynamic libraries or #shebang) with their absolute paths into the Nix store. This means that it's trivial for multiple version of the same package to live side-by-side, without causing conflicts. Binaries built with Nix never depend on globally installed libraries but get all their dependencies from the Nix store. A step-by-step introduction to Nix can be found at https://nixos.org/nixos/nix-pills/pr01.html

Let's create a simple Nix derivation for a D program, `hello.d`:
```d
import std.stdio;
void main() {
  writeln("Hello world");
}
```

The Nix derivation would look this:
```nix
with (import <nixpkgs> {});

stdenv.mkDerivation {
  name = "hellod";
  nativeBuildInputs = [ dmd ];
  src = ./.;
  buildPhase = ''
    dmd -of=hello hello.d
  '';
  installPhase = ''
    mkdir -p $out
    mv hello $out/
  '';
}
```

We can now build our app, which will create a symbolic link `result` pointing to the output in the Nix store:
```sh
nix-build default.nix
```

To distribute our app, we can simply provide our Nix file for other to use:



#!/usr/bin/env bash

# Kill the build if anything errors
set -e -x

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    if [[ "${PYBIN}" == *"cp27"* ]] || \
       [[ "${PYBIN}" == *"cp33"* ]] || \
       [[ "${PYBIN}" == *"cp34"* ]] || \
       [[ "${PYBIN}" == *"cp35"* ]]; 
    then
        "${PYBIN}/pip" install -r /io/requirements-doc.txt
        "${PYBIN}/pip" install pytest
        "${PYBIN}/pip" install -U cython
        "${PYBIN}/pip" install argparse
        /io/update_cpp.sh
        "${PYBIN}/pip" install -e /io/
        "${PYBIN}/pip" wheel /io/ -w wheelhouse/
    fi
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/python-crfsuite*.whl; do
    auditwheel repair "$whl" -w /io/wheelhouse/
done

# Install packages and test
for PYBIN in /opt/python/*/bin; do
    if [[ "${PYBIN}" == *"cp27"* ]] || \
       [[ "${PYBIN}" == *"cp33"* ]] || \
       [[ "${PYBIN}" == *"cp34"* ]] || \
       [[ "${PYBIN}" == *"cp35"* ]];
    then
        "${PYBIN}/pip" uninstall -y python-crfsuite
        "${PYBIN}/pip" install python-crfsuite --no-index -f /io/wheelhouse
        "${PYBIN}/pytest" tests --doctest-modules
    fi
done

# If everything works, upload wheels to PyPi
travis=$( cat /io/.travis_tag )
PYBIN34="/opt/python/cp35-cp35m/bin"
if [[ $travis ]]; then
    "${PYBIN34}/pip" install twine;
    "${PYBIN34}/twine" upload --config-file /io/.pypirc /io/wheelhouse/python-crfsuite*.whl;
fi

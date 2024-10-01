#!/bin/sh

TF="tofu"

$TF init
$TF validate
$TF plan
$TF apply


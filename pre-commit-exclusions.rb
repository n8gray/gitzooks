#!/usr/bin/env ruby

# Git pre-commit hook that prevents accidentally committing things that shouldn't be.
#
# Modify the regexps to suit your needs. The error message shows the full regexp match, or just the first capture group, if there is one.
#
# To bypass this commit hook (and others), perhaps when defining ":focus" or "show_page" for the first time, commit with the "--no-verify" option.
#
# By Henrik Nyh <http://henrik.nyh.se> 2011-10-08 under the MIT License.
# Modified by Nathan Gray for my own regexes
#
#
# Install:
#
# cd your_project
# curl https://raw.github.com/henrik/dotfiles/master/githooks/pre-commit -o .git/hooks/pre-commit && chmod u+x .git/hooks/pre-commit
#
# Or store it centrally and symlink in your projects:
#
# curl --create-dirs https://raw.github.com/henrik/dotfiles/master/githooks/pre-commit -o ~/.githooks/pre-commit && chmod u+x ~/.githooks/pre-commit
# cd your_project
# ln -s ~/.githooks/pre-commit .git/hooks

# Without this I get errors about "invalid byte sequence in US-ASCII"
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

FORBIDDEN = [
  /\bnocommit\b/i
]

full_diff = `git diff --cached --`

full_diff.scan(%r{^\+\+\+ b/(.+)\n@@.*\n([\s\S]*?)(?:^diff|\z)}).each do |file, diff|
  added = diff.split("\n").select { |x| x.start_with?("+") }.join("\n")
  if FORBIDDEN.any? { |re| added.match(re) }
    puts %{Git hook forbids adding "#{$1 || $&}" to #{file}}
    puts "To commit anyway, use --no-verify"
    exit 1
  end
end

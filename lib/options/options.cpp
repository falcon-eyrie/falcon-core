// ---------------------------------------------------------------------
// This file is part of falcon-core.
//
// Copyright (C) 2015, 2016, 2017 Neuro-Electronics Research Flanders
//
// Falcon-server is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Falcon-server is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with falcon-core. If not, see <http://www.gnu.org/licenses/>.
// ---------------------------------------------------------------------

#include "options.hpp"
#include <vector>

using namespace options;

bool options::get_nested_yaml_node(const YAML::Node &root,
                                   const std::vector<std::string> &path,
                                   YAML::Node &out) {
    out.reset(root);
    for (auto &p : path) {

        if (out[p]) {
            out.reset(out[p]);
        } else {
            return false;
        }
    }
    return true;
}

void options::set_nested_yaml_node(YAML::Node &root,
                                   const std::vector<std::string> &path,
                                   const YAML::Node &value) {
    YAML::Node x;
    if (path.size() == 0) {
        // do nothing
    } else if (path.size() == 1) {
        root[path[0]] = value;
    } else {
        x.reset(root);
        for (auto it = path.begin(); it != path.end(); ++it) {
            if (std::next(it) == path.end()) {
                x[*it] = value;
            } else if (!x[*it]) {
                x[*it] = YAML::Node(YAML::NodeType::Map);
            }
            x.reset(x[*it]);
        }
    }
}

OptionBase::OptionBase(std::string name, ValueBase &value,
                       std::string description, bool required)
    : name_(name), description_(description), required_(required),
      value_(value) {
    if (name.size() == 0) {
        throw std::runtime_error("Option name cannot be empty.");
    }
    path_ = split(name, '/');
}

std::string OptionBase::name() const { return name_; }

std::string OptionBase::description() const { return description_; }

const std::vector<std::string> &OptionBase::path() const { return path_; }

bool OptionBase::is_required() const { return required_; }

void OptionBase::from_yaml(const YAML::Node &node) { value_.from_yaml(node); }

typename YAML::Node OptionBase::to_yaml() const {
    YAML::Node node;
    node = value_.to_yaml();
    return node;
}

OptionBase &OptionBase::required() {
    required_ = true;
    return *(this);
}

OptionBase &OptionBase::optional() {
    required_ = false;
    return *(this);
}

OptionBase &OptionBase::describe(std::string description) {
    description_ = description;
    return *(this);
}

OptionBase &OptionBase::set_null() {
    value_.set_null();
    return *(this);
}

bool OptionBase::is_null() const { return value_.is_null(); }

bool OptionBase::is_nullable() const { return value_.is_nullable(); }

OptionBase &OptionList::operator[](std::string key) {
    for (auto &option : options_) {
        if (option.name() == key) {
            return option;
        }
    }
    throw std::runtime_error("No such option.");
}

void OptionList::remove(std::string key) {
    options_.remove_if([key](const OptionBase &x) { return x.name() == key; });
}

std::vector<std::string> OptionList::options() const {
    std::vector<std::string> opts;
    opts.reserve(options_.size());

    for (auto &option : options_) {
        opts.push_back(option.name());
    }

    return opts;
}

std::vector<std::string> OptionList::required_options() const {
    std::vector<std::string> opts;
    for (auto &option : options_) {
        if (option.is_required()) {
            opts.push_back(option.name());
        }
    }
    return opts;
}

bool OptionList::has_option(std::string name) const noexcept {
    // name = std::regex_replace(name, std::regex("[ _]"), "-");
    return std::any_of(
        options_.begin(), options_.end(),
        [name](const OptionBase &x) { return x.name() == name; });
}

void OptionList::from_yaml(const YAML::Node &node,
                           const option_error_handler &handler, bool check) {
    if (!node.IsMap()) {
        throw std::runtime_error("Expecting YAML map.");
    }

    if (check) {
        for (YAML::const_iterator it = node.begin(); it != node.end(); ++it) {
            std::string basename = it->first.as<std::string>();
            bool exist = has_option(basename);
            if (it->second.IsMap() and !exist) {
                for (YAML::const_iterator it2 = it->second.begin();
                     it2 != it->second.end(); ++it2) {
                    if (!has_option(basename + "/" +
                                    it2->first.as<std::string>()))
                        throw std::runtime_error(
                            "This is not a valid option: " + basename + "/" +
                            it2->first.as<std::string>() +
                            ".\n Possible values are: " + list_options());
                }
            } else if (!exist)
                throw std::runtime_error(
                    "This is not a valid option: " + basename +
                    ".\n Possible values are: " + list_options());
        }
    }

    YAML::Node x;
    // loop through options
    for (auto &option : options_) {
        // check if available in YAML node
        // treat "/" in option name special (e.g. recurse into maps)
        if (get_nested_yaml_node(node, option.path(), x)) {
            if (x.IsNull()) {
                if (option.is_nullable()) {
                    option.set_null();
                    continue;
                } else {
                    throw std::runtime_error("Error setting option " +
                                             option.name() +
                                             ": value cannot be null");
                }
            }

            try {
                option.from_yaml(x);
            } catch (ConversionError &e) {
                if (!handler ||
                    !handler(option.name(), option.is_required(),
                             OptionError::conversion_from_yaml_failed,
                             e.what())) {
                    throw std::runtime_error("Error setting option " +
                                             option.name() + ": " + e.what());
                }
            } catch (ValidationError &e) {
                if (!handler ||
                    !handler(option.name(), option.is_required(),
                             OptionError::validation_failed, e.what())) {
                    throw std::runtime_error("Error setting option " +
                                             option.name() + ": " + e.what());
                }
            }
        } else if (option.is_required()) {
            if (!handler || !handler(option.name(), option.is_required(),
                                     OptionError::requirement_failed, "")) {
                throw std::runtime_error("Missing required option " +
                                         option.name() + ".");
            }
        }
    }
}

YAML::Node OptionList::to_yaml(const option_error_handler &handler) const {
    YAML::Node root = YAML::Node(YAML::NodeType::Map);

    for (auto &option : options_) {
        YAML::Node n;

        if (!option.is_nullable() || !option.is_null()) {
            try {
                n = option.to_yaml();
            } catch (ConversionError &e) {
                if (handler && !handler(option.name(), option.is_required(),
                                        OptionError::conversion_to_yaml_failed,
                                        e.what())) {
                    throw std::runtime_error("Error exporting option " +
                                             option.name() + ": " + e.what());
                }
            } catch (SkipError &e) {
                continue;
            } catch (...) {
                throw std::runtime_error("Unknown error for option " +
                                         option.name());
            }
        }
        set_nested_yaml_node(root, option.path(), n);
    }
    return root;
}

void OptionList::load_yaml(std::string filename,
                           const option_error_handler &handler) {
    YAML::Node root = YAML::LoadFile(filename);
    from_yaml(root, handler);
}

void OptionList::save_yaml(std::string filename,
                           const option_error_handler &handler) const {
    auto node = to_yaml(handler);

    YAML::Emitter yaml_emitter;
    yaml_emitter << node;

    std::ofstream out(filename);
    out << yaml_emitter.c_str();
}

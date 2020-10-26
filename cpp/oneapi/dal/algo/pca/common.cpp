/*******************************************************************************
* Copyright 2020 Intel Corporation
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*******************************************************************************/

#include "oneapi/dal/algo/pca/common.hpp"
#include "oneapi/dal/exceptions.hpp"

namespace oneapi::dal::pca {

template <>
class detail::descriptor_impl<task::dim_reduction> : public base {
public:
    std::int64_t component_count = -1;
    bool deterministic = false;
};

template <>
class detail::model_impl<task::dim_reduction> : public base {
public:
    table eigenvectors;
};

using detail::descriptor_impl;
using detail::model_impl;

template <typename Task>
descriptor_base<Task>::descriptor_base() : impl_(new descriptor_impl{}) {}

template <>
std::int64_t descriptor_base<task::dim_reduction>::get_component_count() const {
    return impl_->component_count;
}

template <>
bool descriptor_base<task::dim_reduction>::get_deterministic() const {
    return impl_->deterministic;
}

template <>
void descriptor_base<task::dim_reduction>::set_component_count_impl(std::int64_t value) {
    if (value < 0) {
        throw domain_error("Descriptor component_count should be >= 0");
    }
    impl_->component_count = value;
}

template <>
void descriptor_base<task::dim_reduction>::set_deterministic_impl(bool value) {
    impl_->deterministic = value;
}

template <typename Task>
model<Task>::model() : impl_(new model_impl{}) {}

template <typename Task>
table model<Task>::get_eigenvectors() const {
    return impl_->eigenvectors;
}

template <typename Task>
void model<Task>::set_eigenvectors_impl(const table& value) {
    impl_->eigenvectors = value;
}

template class ONEDAL_EXPORT descriptor_base<task::dim_reduction>;
template class ONEDAL_EXPORT model<task::dim_reduction>;

} // namespace oneapi::dal::pca

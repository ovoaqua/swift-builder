/*
 Copyright (c) 2020 Swift Models Generated from JSON powered by http://www.json4swift.com

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

 */

import Foundation
struct LifecycleStubsEvents: Codable {
    let app_version: String?
    let event_number: Int?
    let expected_data: LifecycleStubsExpected?
    let timestamp: String?
    let timestamp_unix: String?
    let timezone: String?

    enum CodingKeys: String, CodingKey {

        case app_version = "app_version"
        case event_number = "event_number"
        case expected_data = "expected_data"
        case timestamp = "timestamp"
        case timestamp_unix = "timestamp_unix"
        case timezone = "timezone"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        app_version = try values.decodeIfPresent(String.self, forKey: .app_version)
        event_number = try values.decodeIfPresent(Int.self, forKey: .event_number)
        expected_data = try values.decodeIfPresent(LifecycleStubsExpected.self, forKey: .expected_data)
        timestamp = try values.decodeIfPresent(String.self, forKey: .timestamp)
        timestamp_unix = try values.decodeIfPresent(String.self, forKey: .timestamp_unix)
        timezone = try values.decodeIfPresent(String.self, forKey: .timezone)
    }

}

//
//  SJCloudServer.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation
import Alamofire

class SJCloudServer {
    static let TAG = "SJCloudServer"
    static let client = Alamofire.Session.default
    
    static func requestForVehicle(
        vehiclePlate: String,
        onSuccess: @escaping (SJVehicleSession) -> Void,
        onFail: @escaping (Error) -> Void
    ) {
        let params: Parameters = [
            "data": [
                "identify_by": "plate",
                "identify_value": vehiclePlate
            ]
        ]
        deliver(
            path: "/api/v2/fleet/keyless_sdk_session",
            jsonBody: params,
            onSuccess: { jsonResponse in
                do {
                    let jsonObj = try JSONSerialization.jsonObject(with: jsonResponse, options: []) as? [String: Any]
                    let session = try SJVehicleSession.fromJsonData(data: jsonObj!["data"]!)
                    onSuccess(session)
                } catch {
                    onFail(error)
                }
            },
            onFail: onFail
        )
    }
    
    static func deviceCommand(
        vehicleId: Int,
        code: String,
        onComplete: @escaping (SJResult) -> Void
    ) {
        let params: Parameters = [
            "data": [
                "identify_by": "id",
                "identify_value": "\(vehicleId)",
                "command_code": code
            ] as [String : Any]
        ]
        deliver(
            path: "/api/v2/fleet/device_command.json",
            jsonBody: params,
            onSuccess: { jsonResponse in
                do {
                    let jsonObj = try JSONSerialization.jsonObject(with: jsonResponse, options: []) as! [String: Any]
                    if jsonObj["code"] as? Int == 0 {
                        onComplete(SJResult(isSuccess: true))
                    } else {
                        onComplete(SJResult(error: SJError.sjServerException, data: jsonObj))
                    }
                } catch let error {
                    onComplete(SJResult(error: SJError.sjException, data: error))
                }
            },
            onFail: { error in
                onComplete(SJResult(error: SJError.sjException, data: error))
            }
        )
    }
    
    private static func deliver(
        path: String,
        jsonBody: Parameters,
        onSuccess: @escaping (Data) -> Void,
        onFail: @escaping (Error) -> Void
    ) {
        NSLog("\(TAG) deliver: \(path) | \(jsonBody)")
        guard let key = SJAppState.shared.apiKey else {
            onFail(NSError(domain: "SJAppState.shared.apiKey not found", code: 0, userInfo: nil))
            return
        }
        
        let url = "\(SJAppState.shared.baseUrl)\(path)"
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "sj-api-key": key
        ]
        AF.request(url, method: .post, parameters: jsonBody, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    onSuccess(data)
                case .failure(let error):
                    let errorData = ["response":response, "error": error] as [String : Any]
                    onFail(NSError(domain: "Reponse Failed \(error)", code: 0, userInfo: errorData))
                }
            }
    }
    
}

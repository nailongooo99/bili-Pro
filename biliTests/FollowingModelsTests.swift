import XCTest

final class FollowingModelsTests: XCTestCase {
    func testFollowingPageDecodesCommonRelationPayload() throws {
        let data = Data(#"{"list":[{"mid":42,"uname":"Creator","face":"https://example.com/face.jpg","sign":"Hello","special":true}],"total":1,"pn":1,"ps":50,"has_more":false}"#.utf8)
        let page = try JSONDecoder().decode(FollowingPage.self, from: data)
        XCTAssertEqual(page.list.first?.mid, 42)
        XCTAssertEqual(page.list.first?.name, "Creator")
        XCTAssertEqual(page.hasMore, false)
    }

    func testFollowingTagDecodesTagID() throws {
        let data = Data(#"{"tagid":7,"name":"Favorites","count":3}"#.utf8)
        let tag = try JSONDecoder().decode(FollowingTag.self, from: data)
        XCTAssertEqual(tag.tagID, 7)
        XCTAssertEqual(tag.name, "Favorites")
        XCTAssertEqual(tag.count, 3)
    }
}

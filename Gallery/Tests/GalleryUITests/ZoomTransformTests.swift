import CoreGraphics
import Testing

@testable import GalleryUI

struct ZoomTransformTests {
    private let container = CGSize(width: 400, height: 800)
    private let content = CGSize(width: 400, height: 300)
    private let centre = CGPoint(x: 200, y: 400)

    @Test func init_isTheIdentity() {
        let transform = ZoomTransform()

        #expect(transform.scale == 1)
        #expect(transform.offset == .zero)
        #expect(transform.isZoomed == false)
    }

    @Test func magnified_scalesByTheMagnification() {
        let transform = ZoomTransform().magnified(by: 2, anchor: centre, container: container, content: content)

        #expect(transform.scale == 2)
    }

    @Test func magnified_neverGoesBelowOneOrAboveTheMaximum() {
        let belowOne = ZoomTransform().magnified(by: 0.5, anchor: centre, container: container, content: content)
        let aboveMaximum = ZoomTransform().magnified(by: 10, anchor: centre, container: container, content: content)

        #expect(belowOne.scale == 1)
        #expect(aboveMaximum.scale == ZoomTransform.maximumScale)
    }

    @Test func magnified_keepsTheAnchorPointUnderTheFingers() {
        let transform = ZoomTransform().magnified(
            by: 2, anchor: CGPoint(x: 300, y: 400), container: container, content: content)

        #expect(transform.offset.width == -100)
    }

    @Test func magnified_clampsTheOffsetSoTheImageCoversTheEdges() {
        let transform = ZoomTransform().magnified(
            by: 3, anchor: CGPoint(x: 400, y: 0), container: container, content: content)

        #expect(transform.offset == CGSize(width: -400, height: 50))
    }

    @Test func magnified_backToOneResetsTheOffset() {
        let zoomed = ZoomTransform().magnified(
            by: 2, anchor: CGPoint(x: 300, y: 400), container: container, content: content)

        let backToOne = zoomed.magnified(by: 0.5, anchor: centre, container: container, content: content)

        #expect(backToOne.scale == 1)
        #expect(backToOne.offset == .zero)
    }

    @Test func toggled_zoomsToTheDoubleTapScaleTowardsTheTappedPoint() {
        let transform = ZoomTransform().toggled(
            at: CGPoint(x: 300, y: 400), container: container, content: content)

        #expect(transform.scale == ZoomTransform.doubleTapScale)
        #expect(transform.offset == CGSize(width: -150, height: 0))
    }

    @Test func toggled_whenZoomedReturnsToTheIdentity() {
        let zoomed = ZoomTransform().toggled(at: centre, container: container, content: content)

        let transform = zoomed.toggled(at: centre, container: container, content: content)

        #expect(transform == ZoomTransform())
    }

    @Test func panned_movesTheImageWithinItsBounds() {
        let zoomed = ZoomTransform().magnified(by: 2, anchor: centre, container: container, content: content)

        let small = zoomed.panned(by: CGSize(width: 50, height: 30), container: container, content: content)
        let large = zoomed.panned(by: CGSize(width: 500, height: 0), container: container, content: content)

        #expect(small.offset == CGSize(width: 50, height: 0))
        #expect(large.offset.width == 200)
    }

    @Test func panned_atOneKeepsTheImageCentred() {
        let transform = ZoomTransform().panned(
            by: CGSize(width: 50, height: 50), container: container, content: content)

        #expect(transform.offset == .zero)
    }

    @Test func dismissProgress_growsWithTheDownwardDragUpToOne() {
        #expect(ZoomTransform.dismissProgress(for: .zero) == 0)
        #expect(ZoomTransform.dismissProgress(for: CGSize(width: 0, height: 150)) == 0.5)
        #expect(ZoomTransform.dismissProgress(for: CGSize(width: 0, height: 600)) == 1)
    }

    @Test func dismissProgress_isZeroForAnUpwardDrag() {
        #expect(ZoomTransform.dismissProgress(for: CGSize(width: 0, height: -100)) == 0)
    }

    @Test func shouldDismiss_whenDraggedPastTheDistance() {
        let translation = CGSize(width: 0, height: 130)

        #expect(ZoomTransform.shouldDismiss(translation: translation, predictedEnd: translation))
    }

    @Test func shouldDismiss_whenFlickedDown() {
        #expect(
            ZoomTransform.shouldDismiss(
                translation: CGSize(width: 0, height: 20), predictedEnd: CGSize(width: 0, height: 350)))
    }

    @Test func shouldDismiss_neverForAShortSlowOrUpwardDrag() {
        #expect(
            !ZoomTransform.shouldDismiss(
                translation: CGSize(width: 0, height: 50), predictedEnd: CGSize(width: 0, height: 60)))
        #expect(
            !ZoomTransform.shouldDismiss(
                translation: CGSize(width: 0, height: -200), predictedEnd: CGSize(width: 0, height: -400)))
    }

    @Test func shouldShowInfo_whenDraggedUpPastTheDistance() {
        let translation = CGSize(width: 10, height: -90)

        #expect(ZoomTransform.shouldShowInfo(translation: translation, predictedEnd: translation))
    }

    @Test func shouldShowInfo_whenFlickedUp() {
        #expect(
            ZoomTransform.shouldShowInfo(
                translation: CGSize(width: 0, height: -20), predictedEnd: CGSize(width: 0, height: -250)))
    }

    @Test func shouldShowInfo_neverForAShortSidewaysOrDownwardDrag() {
        #expect(
            !ZoomTransform.shouldShowInfo(
                translation: CGSize(width: 0, height: -30), predictedEnd: CGSize(width: 0, height: -40)))
        #expect(
            !ZoomTransform.shouldShowInfo(
                translation: CGSize(width: -200, height: -100), predictedEnd: CGSize(width: -400, height: -200)))
        #expect(
            !ZoomTransform.shouldShowInfo(
                translation: CGSize(width: 0, height: 200), predictedEnd: CGSize(width: 0, height: 400)))
    }
}

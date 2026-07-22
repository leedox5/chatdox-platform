require "test_helper"

class LegalPagesTest < ActionDispatch::IntegrationTest
  test "terms page is restructured into common sections plus a per-product scope table" do
    get terms_path
    assert_response :success

    assert_match(/총칙/, response.body)
    assert_match(/계정 및 이용자 의무/, response.body)
    assert_match(/라이선스 일반 원칙/, response.body)
    assert_match(/상품별 제공 범위/, response.body)
    assert_match(/결제·환불/, response.body)
    assert_match(/면책·분쟁해결/, response.body)

    doc = Nokogiri::HTML(response.body)
    table = doc.at_css("table")
    assert table, "expected a per-product scope table"
    rows = table.css("tbody tr").map { |row| row.css("td").map(&:text) }
    assert_equal 2, rows.size
    assert_equal "Chatdox", rows[0][0]
    assert_equal "포함", rows[0][2]
    assert_equal "포함(수동 초대)", rows[0][3]
    assert_equal "Claudox", rows[1][0]
    assert_equal "미포함", rows[1][2]
    assert_equal "미포함", rows[1][3]
  end

  test "terms page preserves every existing Chatdox legal clause verbatim after the restructure" do
    get terms_path
    assert_response :success
    body = response.body

    # Common license principles carried over from the old 제4조/제4조의2.
    assert_match(/기간제 선불 라이선스 방식으로 제공되며, 별도 동의 없는 자동 갱신이나 정기 결제는 이루어지지 않습니다/, body)
    assert_match(/1개월, 3개월, 6개월, 12개월 중 선택할 수 있/, body)
    assert_match(/결제일을 포함한 7일 이내에서 이용자가 선택할 수 있으며/, body)
    assert_match(/한국 표준시\(KST\) 기준으로 계산되며, 마지막 이용일 다음 날 00:00부터 접근이 종료/, body)
    assert_match(/이용 시작 전 결제를 취소하는 경우 원칙적으로 전액 환불/, body)
    assert_match(/청약철회가 인정되는 경우에 한하여/, body)

    # New common policy statements required by this round.
    assert_match(/부가가치세\(VAT\)가 포함된 금액/, body)
    assert_match(/소급하여 영향을 받지 않습니다/, body)
    assert_match(/이용 기간이 합산되지 않습니다/, body)
    assert_match(/제3자에게 양도하거나 공유할 수 없습니다/, body)

    # Chatdox-specific clauses (old 제5조의2/제5조의3) -- substance must survive intact.
    assert_match(/원본 또는 이와 실질적으로 유사한 형태의 소스 코드를 재판매·재배포하는 행위/, body)
    assert_match(/템플릿이나 강의 형태로 재구성하여 판매하는 행위/, body)
    assert_match(/GitHub 저장소 및 콘텐츠 접근 권한을 타인과 공유하는 행위/, body)
    assert_match(/회사의 사전 동의 없이 Chatdox 또는 LEEDOX 명칭을 사용하는 행위/, body)
    assert_match(/하나의 라이선스는 이용자가 등록한 하나의 GitHub 계정에 대해서만 저장소 접근 권한을 부여/, body)
    assert_match(/정당하게 내려받은 소스 코드 및 이를 기반으로 제작한 결과물은 계속 사용, 운영 및 수익화할 수 있습니다/, body)

    # Common misconduct/liability/change/contact clauses carried over unchanged.
    assert_match(/타인의 계정 또는 결제 정보를 무단으로 사용하는 행위/, body)
    assert_match(/천재지변, 통신 장애, 결제대행사 또는 외부 플랫폼 장애/, body)
    assert_match(/leedox@naver\.com/, body)
  end

  test "terms page adds Claudox-specific scope without a GitHub or source-code entitlement" do
    get terms_path
    assert_response :success
    body = response.body

    assert_match(/Claudox 이용 기간 중에는 협업 스토리 콘텐츠\(챕터\)/, body)
    assert_match(/소스 코드 및 GitHub 저장소 접근은 Claudox 이용 범위에 포함되지 않습니다/, body)
  end

  test "privacy page no longer names Chatdox specifically" do
    get privacy_path
    assert_response :success

    doc = Nokogiri::HTML(response.body)
    assert_no_match(/Chatdox/, doc.at_css("title").text)
    assert_no_match(/Chatdox/, doc.at_css("div.space-y-8").text)
    assert_match(/GitHub 저장소 접근이 포함된 상품을 이용하는 경우/, response.body)
  end
end

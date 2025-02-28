# frozen_string_literal: true

RSpec.describe LieuxController, type: :controller do
  render_views

  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:lieu) { create(:lieu, latitude: 50.63, longitude: 3.06, organisation: organisation) }
  let(:lieu2) { create(:lieu, latitude: 50.72, longitude: 3.16, organisation: organisation) }
  let(:motif) { create(:motif, reservable_online: true, organisation: organisation) }
  let(:now) { Date.new(2019, 7, 22) }
  let(:mock_geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.all) }

  before do
    travel_to(now)

    allow(mock_geo_search).to receive(:attributed_organisations).and_return(Organisation.where(id: organisation.id))
    allow(Users::GeoSearch).to receive(:new)
      .with(departement: "62", city_code: "62100", street_ban_id: nil)
      .and_return(mock_geo_search)
  end

  describe "GET #show" do
    context "pour un motif" do
      subject do
        get :show,
            params: { id: lieu, search: { departement: "62", city_code: "62100", where: "useless 12345", service: motif.service_id, motif_name_with_location_type: motif.name_with_location_type } }
      end

      before do
        allow(Users::CreneauxSearch).to receive(:new).with(
          user: nil,
          motif: motif,
          lieu: lieu,
          date_range: (Date.new(2019, 7, 22)..Date.new(2019, 7, 28)),
          geo_search: mock_geo_search
        ).and_return(mock_creneaux_search)
        subject
      end

      context "creneaux are available soon" do
        let(:mock_creneaux_search) do
          instance_double(
            Users::CreneauxSearch,
            creneaux: [build(:creneau, starts_at: DateTime.parse("2019-07-22 08h00"))]
          )
        end

        it "returns a success response" do
          expect(response).to be_successful
        end

        it "returns a creneau" do
          expect(response.body).to include("08:00")
        end
      end

      context "when first availability is in the future" do
        let(:mock_creneaux_search) do
          instance_double(
            Users::CreneauxSearch,
            creneaux: [],
            next_availability: build(:creneau, starts_at: DateTime.parse("2019-08-05 08h00"))
          )
        end

        it "returns a success response" do
          expect(response).to be_successful
        end

        it "returns next availability" do
          expect(response.body).to match(/Prochaine disponibilité le(.)*lundi 05 août 2019 à 08h00/)
        end
      end
    end

    context "pour un rendez-vous de suivi" do
      subject do
        get :show, params: {
          id: lieu,
          search: {
            departement: "62",
            city_code: "62100",
            where: "useless 12345",
            service: motif.service_id,
            motif_name_with_location_type: motif.name_with_location_type
          }
        }
      end

      let(:lieu) { create(:lieu, latitude: 50.63, longitude: 3.06, organisation: organisation) }
      let(:motif) { create(:motif, reservable_online: true, follow_up: true, organisation: organisation) }

      context "avec un usager non connecté" do
        it "redirige vers la page de login" do
          subject
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:notice]).to eq("Le RDV '#{motif.name}' est disponible uniquement pour les personnes déjà suivies. Veuillez vous connecter pour prendre ce type de RDV.")
        end
      end

      context "avec un usager connecté avec agent référent" do
        let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
        let(:user) { create(:user, agents: [agent]) }

        before do
          sign_in user

          allow(Users::CreneauxSearch).to receive(:new).with(
            user: user,
            motif: motif,
            lieu: lieu,
            date_range: (Date.new(2019, 7, 22)..Date.new(2019, 7, 28)),
            geo_search: mock_geo_search
          ).and_return(mock_creneaux_search)

          subject
        end

        context "creneaux dispos" do
          let(:mock_creneaux_search) do
            instance_double(
              Users::CreneauxSearch,
              creneaux: [build(:creneau, starts_at: DateTime.parse("2019-07-22 08h00")), build(:creneau, starts_at: DateTime.parse("2019-07-22 09h00"))]
            )
          end

          it "propose les créneaux" do
            subject
            expect(response).to be_successful
            expect(flash[:notice]).to be_nil
            expect(assigns(:creneaux).count).to eq(2)
            expect(assigns(:next_availability)).to be_nil
          end
        end

        context "sans créneaux dispo sur la semaine qui arrive" do
          let(:mock_creneaux_search) do
            instance_double(
              Users::CreneauxSearch,
              creneaux: [],
              next_availability: build(:creneau, starts_at: DateTime.parse("2019-11-25 07h00"))
            )
          end

          it "shows next availability" do
            subject
            expect(response).to be_successful
            expect(assigns(:creneaux)).to be_empty
            expect(assigns(:next_availability).starts_at).to eq(Time.utc(2019, 11, 25, 7, 0, 0).in_time_zone("CET"))
          end
        end
      end

      context "avec un usager connecté mais sans agent référents" do
        let(:user) { create(:user, agents: []) }

        before { sign_in user }

        it "annonce qu'il n'y a pas de créneaux parce que pas de référent" do
          subject
          expect(response).to be_successful
          expect(assigns[:referent_missing]).to eq("Vous ne semblez pas bénéficier d’un accompagnement ou d’un suivi, merci de choisir un autre motif ou de contacter votre département au .")
          expect(assigns[:creneaux]).to be_empty
          expect(assigns(:next_availability)).to be_nil
        end
      end
    end
  end

  describe "GET #index" do
    subject do
      get :index,
          params: { search: { departement: "62", city_code: "62100", where: "useless 12345",
                              service: motif.service_id,
                              motif_name_with_location_type: motif.name_with_location_type,
                              latitude: lieu.latitude, longitude: lieu.longitude } }
    end

    before do
      allow(Lieu).to receive(:with_open_slots_for_motifs).and_return(Lieu.all)
      allow(Users::CreneauxSearch).to \
        receive(:new)
        .with(
          user: nil,
          motif: motif,
          lieu: lieu,
          date_range: (Date.new(2019, 7, 15)..Date.new(2019, 7, 22)),
          geo_search: mock_geo_search
        )
        .and_return(
          instance_double(
            Users::CreneauxSearch,
            creneaux: [],
            next_availability: build(:creneau, starts_at: DateTime.parse("2019-07-22 08h00"), motif: build(:motif, organisation: organisation))
          )
        )

      allow(Users::CreneauxSearch).to \
        receive(:new)
        .with(
          user: nil,
          motif: motif,
          lieu: lieu2,
          date_range: (Date.new(2019, 7, 15)..Date.new(2019, 7, 22)),
          geo_search: mock_geo_search
        )
        .and_return(
          instance_double(
            Users::CreneauxSearch,
            creneaux: [],
            next_availability: build(:creneau, starts_at: DateTime.parse("2019-07-29 08h00", motif: build(:motif, organisation: organisation)))
          )
        )

      subject
    end

    it "returns a success response" do
      expect(response).to be_successful
    end

    it "returns 2 lieux" do
      expect(response.body).to match(/#{lieu.name}(.)*Prochaine disponibilité le(.)*lundi 22 juillet 2019 à 08h00/)
      expect(response.body).to match(/#{lieu2.name}(.)*Prochaine disponibilité le(.)*lundi 29 juillet 2019 à 08h00/)
    end

    it "returns lieu first" do
      expect(assigns(:lieux).first).to eq(lieu)
    end

    context "request is closer to lieu_2" do
      subject do
        get :index,
            params: { search: { departement: "62", city_code: "62100", where: "useless 12345",
                                service: motif.service_id,
                                motif_name_with_location_type: motif.name_with_location_type,
                                latitude: lieu2.latitude, longitude: lieu2.longitude } }
      end

      it "return lieu2 first" do
        expect(assigns(:lieux).first).to eq(lieu2)
      end
    end

    context "with an invitation token" do
      subject do
        get :index,
            params: { search: { departement: "62", city_code: "62100", where: "useless 12345",
                                service: motif.service_id,
                                motif_name_with_location_type: motif.name_with_location_type },
                      invitation_token: "123456" }
      end

      it "stores the token in session" do
        subject
        expect(response).to be_successful
        expect(request.session[:invitation_token]).to eq("123456")
      end
    end
  end
end

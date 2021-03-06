class ChaptersController < ApplicationController
  before_action :set_chapter, only: %i[show edit update destroy
                                       unview add_rating]
  before_action :authenticate_user!, except: %i[index show search]
  before_action :authenticate_not_child, except: %i[index show search
                                                    add_rating unview]

  def index
    @series = Series.find(params[:series_id])
    @seasons = @series.real_seasons.order(:number)
    chapters = []
    @seasons.each do |season|
      chapters << season.chapters.order(:chapter_number)
    end
    @seasons = @seasons.zip(chapters)
  end

  def show
    @user = current_user
    @boole = @user && @user.chapters_views.include?(@chapter)
  end

  def search
    @chapters = []
    if params[:nombre] || params[:pais] || params[:serie] ||
       params[:director] || params[:actor] || params[:genero] ||
       params[:duracion]
      @chapters = Chapter.search(current_user, params[:nombre], params[:pais],
                                 params[:serie], params[:director],
                                 params[:actor], params[:genero],
                                 params[:duracion])
    end
    unless params[:rating_order].blank?
      if params[:rating_order] == '1'
        @chapters.sort! { |a, b| a.rating <=> b.rating }.reverse!
      elsif params[:rating_order] == '2'
        @chapters.sort! { |a, b| a.rating <=> b.rating }
      end
    end
    return if params[:release_date_order].blank?
    if params[:release_date_order] == '1'
      @chapters.sort! { |a, b| a.release_date <=> b.release_date }.reverse!
    elsif params[:release_date_order] == '2'
      @chapters.sort! { |a, b| a.release_date <=> b.release_date }
    end
  end

  def new
    @series = Series.find(params[:series_id])
    unless @series.user == current_user
      return redirect_to series_chapters_path(@series),
                         flash: { warning: 'Acceso no autorizado' }
    end
    @chapter = Chapter.new
  end

  def edit
    return if @series.user == current_user
    redirect_to series_chapter_path(@series, @chapter),
                flash: { warning: 'Acceso no autorizado' }
  end

  def create
    @series = Series.find(params[:series_id])
    temporada = params[:season_number].to_i
    id_temporada = agregar_season(@series, temporada)
    @chapter = Chapter.new(chapter_params.merge(season_id: id_temporada,
                                                  rating: 1.0))
    respond_to do |format|
      if !id_temporada.nil? && @chapter.save
        actualizar_serie(@series)
        format.html do
          redirect_to series_chapter_path(@series, @chapter),
                      flash: { success: 'Capitulo fue creado correctamente' }
        end
        format.json { render :show, status: :created, location: @chapter }
      else
        evaluar_temporada(Season.find(id_temporada)) unless id_temporada.nil?
        if id_temporada.nil?
          flash.now['warning'] = 'Numero de temporada no puede estar vacio'
        end
        format.html { render :new }
        format.json do
          render json: @chapter.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @chapter.update(chapter_params)
        actualizar_serie(@series)
        format.html do
          redirect_to series_chapter_path(@series, @chapter),
                      flash: {
                        success: 'Capitulo fue actualizado correctamente'
                      }
        end
        format.json { render :show, status: :ok, location: @chapter }
      else
        format.html { render :edit }
        format.json do
          render json: @chapter.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    temporada = @chapter.season
    @chapter.destroy
    series = temporada.series
    evaluar_temporada(temporada)
    actualizar_serie(series)
    respond_to do |format|
      format.html do
        redirect_to series_chapters_path(@series),
                    flash: { success: 'Capitulo fue destruido correctamente' }
      end
      format.json { head :no_content }
    end
  end

  def add_rating
    user = current_user
    if user.chapters_views.include?(@chapter)
      actual = @chapter.ratings.where(user_id: user.id).first
      if actual.nil?
        ChaptersRating.create(user_id: user.id,
                              chapter_id: @chapter.id,
                              rating: params[:rating].to_i)
      else
        actual.rating = params[:rating].to_i
        actual.save
      end
      recalcular_rating(@chapter)
    end
    redirect_to series_chapter_path(@series, @chapter)
  end

  def unview
    user = current_user
    if user.chapters_views.include?(@chapter)
      user.chapters_views.delete(@chapter)
      rating = @chapter.ratings.where(user_id: user.id).first
      if rating
        rating.destroy
        recalcular_rating @chapter
      end
    else
      user.chapters_views << @chapter
    end
    redirect_to series_chapter_path(@series, @chapter)
  end

  private

  def agregar_season(serie, numero_temporada)
    return nil if numero_temporada < 1
    temporada = serie.real_seasons.where(number: numero_temporada)
    if temporada.empty?
      temporada = Season.new(series_id: serie.id, number: numero_temporada)
      temporada.save
    else
      temporada = temporada.first
    end
    temporada.id
  end

  def evaluar_temporada(temporada)
    temporada.destroy if temporada.chapters.empty?
  end

  def set_chapter
    @chapter = Chapter.find(params[:id])
    @series = Series.find(params[:series_id])
  end

  def chapter_params
    params.require(:chapter).permit(:name, :duration, :release_date,
                                    :rating, :chapter_number)
  end
end
